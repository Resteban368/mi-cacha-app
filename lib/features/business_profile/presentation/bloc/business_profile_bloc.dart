import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogs/domain/entities/catalog_amenity.dart';
import '../../../../core/catalogs/domain/usecases/get_catalogs.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/business.dart';
import '../../../../core/media/image_upload.dart';
import '../../domain/usecases/business_photo_usecases.dart';
import '../../domain/usecases/get_my_business.dart';
import '../../domain/usecases/save_business.dart';

part 'business_profile_event.dart';
part 'business_profile_state.dart';

class BusinessProfileBloc
    extends Bloc<BusinessProfileEvent, BusinessProfileState> {
  BusinessProfileBloc({
    required GetMyBusiness getMyBusiness,
    required SaveBusiness saveBusiness,
    required AddBusinessPhoto addPhoto,
    required RemoveBusinessPhoto removePhoto,
    required ReorderBusinessPhotos reorderPhotos,
    required GetCatalogs getCatalogs,
  }) : _getMyBusiness = getMyBusiness,
       _getCatalogs = getCatalogs,
       _saveBusiness = saveBusiness,
       _addPhoto = addPhoto,
       _removePhoto = removePhoto,
       _reorderPhotos = reorderPhotos,
       super(const BusinessProfileState()) {
    on<BusinessProfileRequested>(_onRequested, transformer: restartable());
    on<BusinessAmenitiesRequested>(
      _onAmenitiesRequested,
      transformer: restartable(),
    );
    // droppable: evita guardar dos veces con un doble toque.
    on<BusinessProfileSaved>(_onSaved, transformer: droppable());
    // Una sola operación de la galería a la vez (subir, quitar u ordenar).
    on<BusinessPhotoEvent>(_onPhoto, transformer: droppable());
  }

  final GetMyBusiness _getMyBusiness;
  final GetCatalogs _getCatalogs;
  final SaveBusiness _saveBusiness;
  final AddBusinessPhoto _addPhoto;
  final RemoveBusinessPhoto _removePhoto;
  final ReorderBusinessPhotos _reorderPhotos;

  Future<void> _onRequested(
    BusinessProfileRequested event,
    Emitter<BusinessProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BusinessProfileStatus.loading,
        amenityStatus: AmenityCatalogStatus.loading,
      ),
    );
    // Negocio y catálogo en paralelo.
    final catalog = _loadAmenities();
    try {
      final business = await _getMyBusiness(const NoParams());
      final (options, amenityStatus) = await catalog;
      emit(
        BusinessProfileState(
          status: BusinessProfileStatus.ready,
          business: business,
          amenityOptions: options,
          amenityStatus: amenityStatus,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: BusinessProfileStatus.failure));
    }
  }

  Future<void> _onAmenitiesRequested(
    BusinessAmenitiesRequested event,
    Emitter<BusinessProfileState> emit,
  ) async {
    emit(state.copyWith(amenityStatus: AmenityCatalogStatus.loading));
    final (options, amenityStatus) = await _loadAmenities();
    emit(state.copyWith(amenityOptions: options, amenityStatus: amenityStatus));
  }

  Future<(List<CatalogAmenity>, AmenityCatalogStatus)> _loadAmenities() async {
    try {
      final catalogs = await _getCatalogs(const NoParams());
      return (
        catalogs.amenities.where((a) => a.active).toList(),
        AmenityCatalogStatus.ready,
      );
    } catch (_) {
      return (const <CatalogAmenity>[], AmenityCatalogStatus.failure);
    }
  }

  /// La API rechaza servicios desactivados en el panel: solo se envían los
  /// que siguen en el catálogo (si no se pudo cargar, se envía lo que hay).
  BusinessDraft _withActiveAmenities(BusinessDraft draft) {
    if (state.amenityStatus != AmenityCatalogStatus.ready) return draft;
    final active = {for (final a in state.amenityOptions) a.code};
    return draft.copyWith(
      amenities: draft.amenities.where(active.contains).toSet(),
    );
  }

  Future<void> _onSaved(
    BusinessProfileSaved event,
    Emitter<BusinessProfileState> emit,
  ) async {
    final isNew = state.business == null;
    emit(state.copyWith(saveStatus: BusinessSaveStatus.saving));
    try {
      var saved = await _saveBusiness(_withActiveAmenities(event.draft));
      final pending = state.pendingPhoto;
      if (pending != null) {
        // La foto elegida al crear se sube apenas existe el negocio. Si
        // falla, el negocio igual quedó registrado.
        emit(state.copyWith(photoStatus: BusinessPhotoStatus.uploading));
        try {
          saved = await _addPhoto(pending);
          emit(state.copyWith(photoStatus: BusinessPhotoStatus.idle));
        } catch (_) {
          emit(state.copyWith(photoStatus: BusinessPhotoStatus.failure));
        }
      }
      emit(
        state.copyWith(
          business: saved,
          pendingPhoto: () => null,
          saveStatus: isNew
              ? BusinessSaveStatus.created
              : BusinessSaveStatus.updated,
        ),
      );
    } catch (_) {
      emit(state.copyWith(saveStatus: BusinessSaveStatus.failure));
    }
  }

  Future<void> _onPhoto(
    BusinessPhotoEvent event,
    Emitter<BusinessProfileState> emit,
  ) async {
    // Vuelve a idle primero para que el mismo aviso se repita si hace falta.
    emit(state.copyWith(photoStatus: BusinessPhotoStatus.idle));
    final business = state.business;
    switch (event) {
      case BusinessPhotoPicked(:final image):
        final error = image.error;
        if (error != null) {
          emit(state.copyWith(photoStatus: _statusOf(error)));
        } else if (business == null) {
          emit(state.copyWith(pendingPhoto: () => image));
        } else if (!business.canAddPhoto) {
          // La API respondería 400: no se intenta.
          emit(state.copyWith(photoStatus: BusinessPhotoStatus.limitReached));
        } else {
          await _run(
            emit,
            busy: BusinessPhotoStatus.uploading,
            done: BusinessPhotoStatus.uploaded,
            request: () => _addPhoto(image),
          );
        }
      case BusinessPhotoRemoved(photoId: null):
        emit(state.copyWith(pendingPhoto: () => null));
      case BusinessPhotoRemoved(:final photoId?):
        await _run(
          emit,
          busy: BusinessPhotoStatus.removing,
          done: BusinessPhotoStatus.removed,
          request: () => _removePhoto(photoId),
        );
      case BusinessPhotosReordered(:final ids):
        final current = [
          for (final BusinessPhoto p in business?.photos ?? const []) p.id,
        ];
        // La API exige todas las fotos, sin repetir; el mismo orden no se
        // envía.
        final valid =
            ids.length == current.length &&
            ids.toSet().length == ids.length &&
            ids.toSet().containsAll(current);
        if (!valid || _sameOrder(ids, current)) return;
        await _run(
          emit,
          busy: BusinessPhotoStatus.reordering,
          done: BusinessPhotoStatus.reordered,
          request: () => _reorderPhotos(ids),
        );
    }
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _run(
    Emitter<BusinessProfileState> emit, {
    required BusinessPhotoStatus busy,
    required BusinessPhotoStatus done,
    required Future<Business> Function() request,
  }) async {
    emit(state.copyWith(photoStatus: busy));
    try {
      final business = await request();
      emit(state.copyWith(business: business, photoStatus: done));
    } on ImageUploadException catch (error) {
      emit(state.copyWith(photoStatus: _statusOf(error.error)));
    } catch (_) {
      emit(state.copyWith(photoStatus: BusinessPhotoStatus.failure));
    }
  }

  static BusinessPhotoStatus _statusOf(ImageUploadError error) =>
      switch (error) {
        ImageUploadError.tooLarge => BusinessPhotoStatus.tooLarge,
        ImageUploadError.invalidType => BusinessPhotoStatus.invalidType,
      };
}
