part of 'court_form_bloc.dart';

enum CourtFormContextStatus {
  loading,
  ready,
  failure,

  /// La cancha a editar ya no existe (o no es del negocio).
  notFound,
}

enum CourtFormSubmitStatus {
  idle,
  saving,
  uploadingPhotos,
  success,
  failure,

  /// Los datos se guardaron pero algún cambio de foto falló
  /// ([CourtFormState.failedPhotos]).
  photosFailed;

  bool get isBusy => this == saving || this == uploadingPhotos;
}

final class CourtFormState extends Equatable {
  const CourtFormState({
    this.contextStatus = CourtFormContextStatus.loading,
    this.venueName,
    this.hasBusiness = true,
    this.subscription,
    this.planKnown = false,
    this.existingCourts = const [],
    this.editing,
    this.submitStatus = CourtFormSubmitStatus.idle,
    this.photoProgress = (0, 0),
    this.pendingCourt,
    this.completedPhotos = const {},
    this.failedPhotos = const {},
    this.saved,
    this.failure,
    this.failureMessage,
  });

  final CourtFormContextStatus contextStatus;
  final String? venueName;

  /// `false` si el administrador aún no registró su negocio.
  final bool hasBusiness;
  final Subscription? subscription;

  /// Si se pudo leer el plan (si no, la API decide el límite al guardar).
  final bool planKnown;

  /// Canchas ya creadas, de las que se puede copiar horario y tarifas.
  final List<Court> existingCourts;

  /// Cancha que se está editando; `null` al crear.
  final Court? editing;

  final CourtFormSubmitStatus submitStatus;

  /// Cambio de foto en curso: (actual, total).
  final (int, int) photoProgress;

  /// Cancha ya guardada a la que le faltan cambios de fotos.
  final Court? pendingCourt;

  /// Fotos ya aplicadas en este guardado (no se repiten al reintentar).
  final Set<CourtPhotoSlot> completedPhotos;
  final Set<CourtPhotoSlot> failedPhotos;

  /// Cancha guardada con éxito (creada o editada).
  final Court? saved;
  final CourtFailure? failure;

  /// Mensaje del backend (límite del plan, validaciones de horario/tarifas).
  final String? failureMessage;

  bool get isEditing => editing != null;

  /// Canchas de las que se puede copiar (sin la que se está editando).
  List<Court> get copySources => [
    for (final court in existingCourts)
      if (court.id != editing?.id) court,
  ];

  /// Si la cancha puede quedar activa. Una cancha que ya está activa sigue
  /// pudiendo estarlo; activar una nueva o inactiva necesita cupo en el plan.
  bool get canActivate {
    if (editing?.isActive ?? false) return true;
    if (!planKnown) return true;
    final plan = subscription;
    if (plan == null || !plan.isActive) return false;
    return plan.courtsInUse < plan.courtLimit;
  }

  CourtFormState copyWith({
    CourtFormContextStatus? contextStatus,
    String? Function()? venueName,
    bool? hasBusiness,
    Subscription? Function()? subscription,
    bool? planKnown,
    List<Court>? existingCourts,
    Court? Function()? editing,
    CourtFormSubmitStatus? submitStatus,
    (int, int)? photoProgress,
    Court? Function()? pendingCourt,
    Set<CourtPhotoSlot>? completedPhotos,
    Set<CourtPhotoSlot>? failedPhotos,
    Court? Function()? saved,
    CourtFailure? Function()? failure,
    String? Function()? failureMessage,
  }) => CourtFormState(
    contextStatus: contextStatus ?? this.contextStatus,
    venueName: venueName != null ? venueName() : this.venueName,
    hasBusiness: hasBusiness ?? this.hasBusiness,
    subscription: subscription != null ? subscription() : this.subscription,
    planKnown: planKnown ?? this.planKnown,
    existingCourts: existingCourts ?? this.existingCourts,
    editing: editing != null ? editing() : this.editing,
    submitStatus: submitStatus ?? this.submitStatus,
    photoProgress: photoProgress ?? this.photoProgress,
    pendingCourt: pendingCourt != null ? pendingCourt() : this.pendingCourt,
    completedPhotos: completedPhotos ?? this.completedPhotos,
    failedPhotos: failedPhotos ?? this.failedPhotos,
    saved: saved != null ? saved() : this.saved,
    failure: failure != null ? failure() : this.failure,
    failureMessage: failureMessage != null
        ? failureMessage()
        : this.failureMessage,
  );

  @override
  List<Object?> get props => [
    contextStatus,
    venueName,
    hasBusiness,
    subscription,
    planKnown,
    existingCourts,
    editing,
    submitStatus,
    photoProgress,
    pendingCourt,
    completedPhotos,
    failedPhotos,
    saved,
    failure,
    failureMessage,
  ];
}
