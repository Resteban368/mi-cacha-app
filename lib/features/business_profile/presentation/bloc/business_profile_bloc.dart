import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogs/domain/entities/catalog_amenity.dart';
import '../../../../core/catalogs/domain/usecases/get_catalogs.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/business.dart';
import '../../../../core/media/image_upload.dart';
import '../../domain/usecases/get_my_business.dart';
import '../../domain/usecases/remove_business_cover.dart';
import '../../domain/usecases/save_business.dart';
import '../../domain/usecases/upload_business_cover.dart';

part 'business_profile_event.dart';
part 'business_profile_state.dart';

class BusinessProfileBloc
    extends Bloc<BusinessProfileEvent, BusinessProfileState> {
  BusinessProfileBloc({
    required GetMyBusiness getMyBusiness,
    required SaveBusiness saveBusiness,
    required UploadBusinessCover uploadCover,
    required RemoveBusinessCover removeCover,
    required GetCatalogs getCatalogs,
  }) : _getMyBusiness = getMyBusiness,
       _getCatalogs = getCatalogs,
       _saveBusiness = saveBusiness,
       _uploadCover = uploadCover,
       _removeCover = removeCover,
       super(const BusinessProfileState()) {
    on<BusinessProfileRequested>(_onRequested, transformer: restartable());
    on<BusinessAmenitiesRequested>(
      _onAmenitiesRequested,
      transformer: restartable(),
    );
    // droppable: evita guardar dos veces con un doble toque.
    on<BusinessProfileSaved>(_onSaved, transformer: droppable());
    // Una sola operación de foto a la vez (subir o quitar).
    on<BusinessCoverEvent>(_onCover, transformer: droppable());
  }

  final GetMyBusiness _getMyBusiness;
  final GetCatalogs _getCatalogs;
  final SaveBusiness _saveBusiness;
  final UploadBusinessCover _uploadCover;
  final RemoveBusinessCover _removeCover;

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
      final pending = state.pendingCover;
      if (pending != null) {
        // La foto elegida al crear se sube apenas existe el negocio. Si
        // falla, el negocio igual quedó registrado.
        emit(state.copyWith(coverStatus: BusinessCoverStatus.uploading));
        try {
          saved = await _uploadCover(pending);
          emit(state.copyWith(coverStatus: BusinessCoverStatus.idle));
        } catch (_) {
          emit(state.copyWith(coverStatus: BusinessCoverStatus.failure));
        }
      }
      emit(
        state.copyWith(
          business: saved,
          pendingCover: () => null,
          saveStatus: isNew
              ? BusinessSaveStatus.created
              : BusinessSaveStatus.updated,
        ),
      );
    } catch (_) {
      emit(state.copyWith(saveStatus: BusinessSaveStatus.failure));
    }
  }

  Future<void> _onCover(
    BusinessCoverEvent event,
    Emitter<BusinessProfileState> emit,
  ) async {
    // Vuelve a idle primero para que el mismo aviso se repita si hace falta.
    emit(state.copyWith(coverStatus: BusinessCoverStatus.idle));
    final business = state.business;
    switch (event) {
      case BusinessCoverPicked(:final image):
        final error = image.error;
        if (error != null) {
          emit(state.copyWith(coverStatus: _statusOf(error)));
        } else if (business == null) {
          emit(state.copyWith(pendingCover: () => image));
        } else {
          await _run(
            emit,
            busy: BusinessCoverStatus.uploading,
            done: BusinessCoverStatus.uploaded,
            request: () => _uploadCover(image),
          );
        }
      case BusinessCoverRemoved():
        if (business?.imageUrl == null) {
          emit(state.copyWith(pendingCover: () => null));
        } else {
          await _run(
            emit,
            busy: BusinessCoverStatus.removing,
            done: BusinessCoverStatus.removed,
            request: () => _removeCover(const NoParams()),
          );
        }
    }
  }

  Future<void> _run(
    Emitter<BusinessProfileState> emit, {
    required BusinessCoverStatus busy,
    required BusinessCoverStatus done,
    required Future<Business> Function() request,
  }) async {
    emit(state.copyWith(coverStatus: busy));
    try {
      final business = await request();
      emit(state.copyWith(business: business, coverStatus: done));
    } on ImageUploadException catch (error) {
      emit(state.copyWith(coverStatus: _statusOf(error.error)));
    } catch (_) {
      emit(state.copyWith(coverStatus: BusinessCoverStatus.failure));
    }
  }

  static BusinessCoverStatus _statusOf(ImageUploadError error) =>
      switch (error) {
        ImageUploadError.tooLarge => BusinessCoverStatus.tooLarge,
        ImageUploadError.invalidType => BusinessCoverStatus.invalidType,
      };
}
