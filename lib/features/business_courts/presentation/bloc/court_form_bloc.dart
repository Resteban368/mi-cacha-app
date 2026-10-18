import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogs/domain/entities/catalog_court_surface.dart';
import '../../../../core/catalogs/domain/usecases/get_catalogs.dart';
import '../../../../core/media/image_upload.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../business_account/domain/entities/business_account.dart';
import '../../../business_account/domain/usecases/get_business_account.dart';
import '../../../business_profile/domain/usecases/get_my_business.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_failure.dart';
import '../../domain/usecases/create_court.dart';
import '../../domain/usecases/get_courts.dart';
import '../../domain/usecases/remove_court_photo.dart';
import '../../domain/usecases/update_court.dart';
import '../../domain/usecases/upload_court_photo.dart';

part 'court_form_event.dart';
part 'court_form_state.dart';

/// Crear o editar una cancha: guarda sus datos (POST o PATCH) y luego
/// aplica los cambios de fotos de a uno (subir o quitar).
///
/// Si algún cambio de foto falla, los datos ya quedaron guardados: el
/// siguiente envío solo reintenta las fotos pendientes.
class CourtFormBloc extends Bloc<CourtFormEvent, CourtFormState> {
  CourtFormBloc({
    required GetMyBusiness getMyBusiness,
    required GetBusinessAccount getAccount,
    required GetCourts getCourts,
    required GetCatalogs getCatalogs,
    required CreateCourt createCourt,
    required UpdateCourt updateCourt,
    required UploadCourtPhoto uploadPhoto,
    required RemoveCourtPhoto removePhoto,
  }) : _getMyBusiness = getMyBusiness,
       _getAccount = getAccount,
       _getCourts = getCourts,
       _getCatalogs = getCatalogs,
       _createCourt = createCourt,
       _updateCourt = updateCourt,
       _uploadPhoto = uploadPhoto,
       _removePhoto = removePhoto,
       super(const CourtFormState()) {
    on<CourtFormStarted>(_onStarted, transformer: restartable());
    // droppable: un doble toque en "Guardar" no envía dos veces.
    on<CourtFormSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetMyBusiness _getMyBusiness;
  final GetBusinessAccount _getAccount;
  final GetCourts _getCourts;
  final GetCatalogs _getCatalogs;
  final CreateCourt _createCourt;
  final UpdateCourt _updateCourt;
  final UploadCourtPhoto _uploadPhoto;
  final RemoveCourtPhoto _removePhoto;

  Future<void> _onStarted(
    CourtFormStarted event,
    Emitter<CourtFormState> emit,
  ) async {
    if (!event.silent) {
      emit(state.copyWith(contextStatus: CourtFormContextStatus.loading));
    }
    // El plan es informativo: si falla, la API decide el límite al guardar.
    try {
      // En paralelo; si algo falla, `.wait` lo informa sin errores sueltos.
      final (business, (subscription, known), existing, surfaces) = await (
        _getMyBusiness(const NoParams()),
        _loadSubscription(),
        _loadCourts(required: event.courtId != null),
        _loadSurfaces(),
      ).wait;
      final courtId = event.courtId;
      final editing = courtId == null
          ? null
          : existing.where((c) => c.id == courtId).firstOrNull;
      emit(
        state.copyWith(
          contextStatus: courtId != null && editing == null
              ? CourtFormContextStatus.notFound
              : CourtFormContextStatus.ready,
          venueName: () => business?.name,
          hasBusiness: business != null,
          subscription: () => subscription,
          planKnown: known,
          existingCourts: existing,
          courtSurfaces: surfaces,
          editing: () => editing,
        ),
      );
    } catch (_) {
      if (!event.silent) {
        emit(state.copyWith(contextStatus: CourtFormContextStatus.failure));
      }
    }
  }

  /// Canchas ya creadas (para copiar de ellas o editar una). Al crear, si
  /// fallan, el formulario funciona igual sin la opción de copiar; al
  /// editar son necesarias y el error se propaga.
  Future<List<Court>> _loadCourts({required bool required}) async {
    try {
      return await _getCourts(const NoParams());
    } catch (_) {
      if (required) rethrow;
      return const [];
    }
  }

  /// Superficies del catálogo. Si fallan, el formulario funciona igual y
  /// conserva la superficie que ya tenía la cancha.
  Future<List<CatalogCourtSurface>> _loadSurfaces() async {
    try {
      return (await _getCatalogs(const NoParams())).courtSurfaces;
    } catch (_) {
      return const [];
    }
  }

  Future<(Subscription?, bool)> _loadSubscription() async {
    try {
      final account = await _getAccount(const NoParams());
      return (account.subscription, true);
    } catch (_) {
      return (null, false);
    }
  }

  Future<void> _onSubmitted(
    CourtFormSubmitted event,
    Emitter<CourtFormState> emit,
  ) async {
    var court = state.pendingCourt;
    var completed = state.completedPhotos;
    if (court == null) {
      emit(
        state.copyWith(
          submitStatus: CourtFormSubmitStatus.saving,
          failure: () => null,
          failureMessage: () => null,
        ),
      );
      try {
        final editing = state.editing;
        court = editing == null
            ? await _createCourt(event.draft)
            : await _updateCourt((courtId: editing.id, draft: event.draft));
        completed = const {};
      } on CourtException catch (error) {
        emit(
          state.copyWith(
            submitStatus: CourtFormSubmitStatus.failure,
            failure: () => error.failure,
            failureMessage: () => error.message,
          ),
        );
        return;
      } catch (_) {
        emit(
          state.copyWith(
            submitStatus: CourtFormSubmitStatus.failure,
            failure: () => CourtFailure.server,
            failureMessage: () => null,
          ),
        );
        return;
      }
    }

    // Cambios de fotos pendientes, en el orden de las posiciones: quitar
    // (si la cancha la tiene y no se reemplaza) o subir la nueva.
    final ops = [
      for (final slot in CourtPhotoSlot.values)
        if (!completed.contains(slot))
          if (event.uploads[slot] case final image?)
            (slot, image)
          else if (event.removals.contains(slot) &&
              court.photos.containsKey(slot))
            (slot, null),
    ];
    final done = {...completed};
    final failed = <CourtPhotoSlot>{};
    for (final (index, (slot, image)) in ops.indexed) {
      emit(
        state.copyWith(
          submitStatus: CourtFormSubmitStatus.uploadingPhotos,
          pendingCourt: () => court,
          photoProgress: (index + 1, ops.length),
        ),
      );
      try {
        court = image == null
            ? await _removePhoto((courtId: court!.id, slot: slot))
            : await _uploadPhoto((
                courtId: court!.id,
                slot: slot,
                image: image,
              ));
        done.add(slot);
      } catch (_) {
        failed.add(slot);
      }
    }

    if (failed.isNotEmpty) {
      emit(
        state.copyWith(
          submitStatus: CourtFormSubmitStatus.photosFailed,
          pendingCourt: () => court,
          completedPhotos: done,
          failedPhotos: failed,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        submitStatus: CourtFormSubmitStatus.success,
        saved: () => court,
        pendingCourt: () => null,
        completedPhotos: const {},
        failedPhotos: const {},
        failure: () => null,
        failureMessage: () => null,
      ),
    );
  }
}
