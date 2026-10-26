import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../business_setup/presentation/business_setup_gate.dart';
import '../../../../core/catalogs/domain/entities/catalog_court_surface.dart';
import '../../../../core/domain/entities/sport.dart';
import '../../../../core/media/image_upload.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/media/pick_image.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../business_home/presentation/widgets/read_only_banner.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_failure.dart';
import '../../domain/entities/court_schedule.dart';
import '../bloc/court_form_bloc.dart';
import '../../domain/entities/week_day.dart';
import '../widgets/copy_from_court_dialog.dart';
import '../widgets/court_photos_picker.dart';
import '../widgets/court_plan_limit_banner.dart';
import '../../../business_account/presentation/utils/plan_upgrade_whatsapp.dart';
import '../widgets/court_pricing_card.dart';
import '../widgets/court_rate_editor.dart';
import '../widgets/court_rates_section.dart';
import '../widgets/court_section_header.dart';
import '../widgets/court_specs_card.dart';
import '../widgets/court_sport_selector.dart';
import '../widgets/court_structure_selector.dart';
import '../widgets/court_weekly_schedule.dart';
import '../../../../core/widgets/loading_dialog.dart';

/// Formulario para crear (diseño "Crear Cancha") o editar una cancha,
/// conectado a `POST`/`PATCH /business/courts` y a sus fotos. Al crear se
/// puede partir de otra cancha copiando su horario, precio y tarifas.
class CourtFormPage extends StatelessWidget {
  const CourtFormPage({
    super.key,
    required this.photoPicker,
    this.courtId,
    this.copyFromCourtId,
  });

  final PhotoPicker photoPicker;

  /// Cancha a editar; `null` para crear una nueva.
  final String? courtId;

  /// Abre el diálogo de copia con esta cancha elegida ("Usar como base").
  final String? copyFromCourtId;

  @override
  Widget build(BuildContext context) {
    // Al cargar: diálogo con el ícono de la app sobre el fondo difuminado.
    return BlocLoadingDialog<CourtFormBloc, CourtFormState>(
      isLoading: (s) => s.contextStatus == CourtFormContextStatus.loading,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CourtFormBloc, CourtFormState>(
          listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
          listener: _onSubmitStatus,
        ),
      ],
      child: Column(
        children: [
          const AppTopBar(
            title: 'Canchas',
            subtitle: 'Tus canchas, horarios y tarifas',
            icon: Icons.stadium_rounded,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: BlocBuilder<CourtFormBloc, CourtFormState>(
                buildWhen: (prev, curr) =>
                    prev.contextStatus != curr.contextStatus ||
                    prev.hasBusiness != curr.hasBusiness,
                builder: (context, state) => switch (state.contextStatus) {
                  CourtFormContextStatus.loading => const SizedBox.shrink(),
                  CourtFormContextStatus.failure => _Message(
                    icon: Icons.cloud_off_outlined,
                    title: 'No pudimos cargar tu negocio',
                    detail: 'Revisa tu conexión e intenta de nuevo.',
                    actionLabel: 'Reintentar',
                    onAction: () => context.read<CourtFormBloc>().add(
                      CourtFormStarted(courtId: courtId),
                    ),
                  ),
                  CourtFormContextStatus.notFound => _Message(
                    icon: Icons.search_off_rounded,
                    title: 'No encontramos esta cancha',
                    detail: 'Puede que ya no exista. Vuelve a tus canchas.',
                    actionLabel: 'Ver mis canchas',
                    onAction: () => context.go(AppRoutes.businessCourts),
                  ),
                  CourtFormContextStatus.ready when !state.hasBusiness =>
                    _Message(
                      icon: Icons.storefront_outlined,
                      title: 'Primero registra tu negocio',
                      detail:
                          'Las canchas pertenecen a tu sede: completa sus '
                          'datos en Mi negocio y vuelve aquí.',
                      actionLabel: 'Ir a Mi negocio',
                      onAction: () => context.go(AppRoutes.businessProfile),
                    ),
                  // Abierto por URL sin plan activo.
                  CourtFormContextStatus.ready
                      when !WriteAccessScope.canWrite(context) =>
                    const ReadOnlyMessage(action: 'crear ni editar canchas'),
                  CourtFormContextStatus.ready => _CourtForm(
                    photoPicker: photoPicker,
                    editing: state.editing,
                    copyFromCourtId: copyFromCourtId,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmitStatus(BuildContext context, CourtFormState state) {
    final messenger = ScaffoldMessenger.of(context);
    void show(String message, {bool error = false}) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.statusDue : null,
        ),
      );

    if (state.submitStatus
        case CourtFormSubmitStatus.success ||
            CourtFormSubmitStatus.photosFailed) {
      // Puede dejar lista la primera cancha de la configuración inicial.
      BusinessSetupScope.refresh(context);
    }
    switch (state.submitStatus) {
      case CourtFormSubmitStatus.success:
        final court = state.saved!;
        final action = state.isEditing ? 'guardada' : 'creada';
        show(switch (court) {
          Court(isBookable: true) =>
            'Cancha "${court.name}" $action y lista para reservas.',
          Court(isActive: false) =>
            'Cancha "${court.name}" $action. Queda inactiva hasta que la '
                'habilites.',
          _ => 'Cancha "${court.name}" $action. ${_missingPhotosHint(court)}',
        });
        // La lista se recarga y muestra los cambios.
        context.go(AppRoutes.businessCourts);
      case CourtFormSubmitStatus.failure:
        show(_failureMessage(state), error: true);
      case CourtFormSubmitStatus.photosFailed:
        final count = state.failedPhotos.length;
        final saved = state.isEditing
            ? 'Los cambios se guardaron'
            : 'La cancha se creó';
        show(
          count == 1
              ? '$saved, pero 1 foto no se actualizó. Toca '
                    '"Reintentar fotos".'
              : '$saved, pero $count fotos no se actualizaron. Toca '
                    '"Reintentar fotos".',
          error: true,
        );
      case CourtFormSubmitStatus.idle ||
          CourtFormSubmitStatus.saving ||
          CourtFormSubmitStatus.uploadingPhotos:
        break;
    }
  }

  /// Qué falta para recibir reservas, según `missingPhotos` de la API.
  static String _missingPhotosHint(Court court) =>
      switch (court.missingPhotos) {
        [] => 'Aún no puede recibir reservas.',
        [CourtPhotoSlot.main] =>
          'Sube la foto principal para recibir reservas.',
        final missing =>
          'Sube ${missing.map((s) => s.hint.toLowerCase()).join(', ')} para '
              'recibir reservas.',
      };

  static String _failureMessage(CourtFormState state) {
    final message = state.failureMessage;
    return switch (state.failure) {
      CourtFailure.planLimit =>
        message ?? 'Tu plan no permite más canchas activas.',
      CourtFailure.duplicateName =>
        'Ya tienes una cancha con ese nombre. Usa otro.',
      CourtFailure.invalid => message ?? 'Revisa los datos de la cancha.',
      CourtFailure.noBusiness => 'Primero registra tu negocio en Mi negocio.',
      CourtFailure.network =>
        'Sin conexión. Revisa tu internet e intenta de nuevo.',
      CourtFailure.server || null =>
        state.isEditing
            ? 'No pudimos guardar los cambios. Intenta de nuevo.'
            : 'No pudimos crear la cancha. Intenta de nuevo.',
    };
  }
}

class _CourtForm extends StatefulWidget {
  const _CourtForm({
    required this.photoPicker,
    required this.editing,
    this.copyFromCourtId,
  });

  final PhotoPicker photoPicker;

  /// Cancha a editar (precarga el formulario); `null` al crear.
  final Court? editing;
  final String? copyFromCourtId;

  @override
  State<_CourtForm> createState() => _CourtFormState();
}

class _CourtFormState extends State<_CourtForm> {
  /// Desde este ancho el formulario se reparte en dos columnas (web).
  static const _wideBreakpoint = 900.0;

  late final Court? _original = widget.editing;
  late final _name = TextEditingController(text: _original?.name);
  late final _basePrice = TextEditingController(
    text: CopInputFormatter.format(_original?.basePricePerHour ?? 0),
  );
  late Sport? _sport = _original?.sport;
  late var _isCovered = _original?.isCovered ?? false;
  late var _isActive = _original?.isActive ?? true;
  late var _slotDuration = _original?.slotDuration ?? 60;
  late var _schedules = switch (_original?.schedules) {
    final schedules? when schedules.length == WeekDay.values.length => [
      ...schedules,
    ],
    _ => DaySchedule.defaultWeek(),
  };
  late var _rates = [...?_original?.rates];
  late CourtSurfaceRef? _surface = _original?.specs.surface;
  late final _length = TextEditingController(
    text: _metersText(_original?.specs.lengthMeters),
  );
  late final _width = TextEditingController(
    text: _metersText(_original?.specs.widthMeters),
  );
  late final _players = TextEditingController(
    text: _original?.specs.playersPerSide?.toString(),
  );

  /// Fotos elegidas en este formulario (nuevas o reemplazos).
  final _photos = <CourtPhotoSlot, ImageUpload>{};

  /// Fotos ya subidas que se conservan (al editar).
  late final _remotePhotos = {...?_original?.photos};

  /// Al crear: posición de la segunda foto (opcional).
  var _secondSlot = CourtPhotoSlot.surface;

  bool get _isEditing => _original != null;

  bool _hasPhoto(CourtPhotoSlot slot) =>
      _photos.containsKey(slot) || _remotePhotos.containsKey(slot);

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _basePrice.addListener(_refresh);
    _length.addListener(_refresh);
    _width.addListener(_refresh);
    _players.addListener(_refresh);
    // "Usar como base": abre la copia con esa cancha ya elegida.
    if (widget.copyFromCourtId case final id?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final courts = context.read<CourtFormBloc>().state.existingCourts;
        final court = courts.where((c) => c.id == id).firstOrNull;
        if (court != null) _copyFrom(courts, initial: court);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _basePrice.dispose();
    _length.dispose();
    _width.dispose();
    _players.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  static String? _metersText(double? value) => switch (value) {
    null => null,
    final v when v == v.roundToDouble() => '${v.toInt()}',
    final v => '$v'.replaceAll('.', ','),
  };

  static double? _parseMeters(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  static bool _validMeters(double? value) =>
      value != null && value >= courtMinMeters && value <= courtMaxMeters;

  /// Superficies del deporte elegido, más la actual aunque ya no esté en el
  /// catálogo (desactivada o si el catálogo no cargó).
  List<CourtSurfaceRef> _surfacesFor(CourtFormState state) {
    final sport = _sport;
    if (sport == null) return const [];
    final list = [
      for (final s in state.courtSurfaces)
        if (s.appliesTo(sport)) CourtSurfaceRef(code: s.code, name: s.name),
    ];
    final current = _surface;
    if (current != null && !list.any((s) => s.code == current.code)) {
      list.insert(0, current);
    }
    return list;
  }

  /// Al cambiar de deporte se quita la superficie que ya no aplica.
  void _selectSport(Sport sport, List<CatalogCourtSurface> catalog) {
    final current = catalog.where((s) => s.code == _surface?.code).firstOrNull;
    setState(() {
      _sport = sport;
      if (current != null && !current.appliesTo(sport)) _surface = null;
    });
  }

  /// Lo que falta para poder guardar (vacío = listo).
  List<String> get _missing {
    return [
      if (_name.text.trim().isEmpty) 'nombre',
      if (_sport == null) 'deporte',
      if (CopInputFormatter.parse(_basePrice.text) <= 0) 'precio base',
      if (!_schedules.any((s) => s.isOpen)) 'al menos un día abierto',
      ..._specsMissing,
      // Solo la principal es obligatoria; la API confirma con isComplete.
      if (!_hasPhoto(CourtPhotoSlot.main)) 'foto principal',
    ];
  }

  /// Medidas a medias o fuera de rango y formato inválido.
  List<String> get _specsMissing {
    final length = _length.text.trim();
    final width = _width.text.trim();
    final players = int.tryParse(_players.text.trim());
    return [
      if (length.isEmpty != width.isEmpty)
        length.isEmpty ? 'largo de la cancha' : 'ancho de la cancha'
      else if (length.isNotEmpty &&
          !(_validMeters(_parseMeters(length)) &&
              _validMeters(_parseMeters(width))))
        'medidas entre 1 y 200 m',
      if (_players.text.trim().isNotEmpty &&
          (players == null || players < 1 || players > courtMaxPlayersPerSide))
        'jugadores por equipo entre 1 y $courtMaxPlayersPerSide',
    ];
  }

  CourtDraft _draft({required bool canActivate}) => CourtDraft(
    name: _name.text,
    sport: _sport!,
    isCovered: _isCovered,
    isActive: _isActive && canActivate,
    basePricePerHour: CopInputFormatter.parse(_basePrice.text),
    slotDuration: _slotDuration,
    schedules: _schedules,
    rates: _rates,
    specs: CourtSpecs(
      surface: _surface,
      lengthMeters: _parseMeters(_length.text),
      widthMeters: _parseMeters(_width.text),
      playersPerSide: int.tryParse(_players.text.trim()),
    ),
  );

  void _submit(CourtFormState state) {
    FocusScope.of(context).unfocus();
    context.read<CourtFormBloc>().add(
      CourtFormSubmitted(
        draft: _draft(canActivate: state.canActivate),
        uploads: Map.unmodifiable(_photos),
        // Fotos que la cancha tenía y se quitaron (sin reemplazo).
        removals: {
          for (final slot in _original?.photos.keys ?? <CourtPhotoSlot>[])
            if (!_hasPhoto(slot)) slot,
        },
      ),
    );
  }

  /// La foto ya elegida para la segunda posición pasa a la nueva.
  void _changeSecondSlot(CourtPhotoSlot slot) {
    if (slot == _secondSlot) return;
    setState(() {
      if (_photos.remove(_secondSlot) case final image?) _photos[slot] = image;
      _secondSlot = slot;
    });
  }

  Future<void> _pickPhoto(CourtPhotoSlot slot) async {
    final image = await pickImageUpload(context, widget.photoPicker);
    if (image == null || !mounted) return;
    final error = image.error;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(switch (error) {
              ImageUploadError.tooLarge =>
                'La foto supera los 4 MB. Elige una más liviana.',
              ImageUploadError.invalidType => 'La foto debe ser JPG o PNG.',
            }),
            backgroundColor: AppColors.statusDue,
          ),
        );
      return;
    }
    setState(() => _photos[slot] = image);
  }

  Future<void> _copyFrom(List<Court> courts, {Court? initial}) async {
    final copy = await showCopyFromCourtDialog(
      context,
      courts: courts,
      initial: initial,
    );
    if (copy == null || !mounted) return;
    final (:court, :parts) = copy;
    setState(() {
      if (parts.contains(CourtCopyPart.schedule) &&
          court.schedules.length == WeekDay.values.length) {
        _schedules = [...court.schedules];
      }
      if (parts.contains(CourtCopyPart.pricing)) {
        _basePrice.text = CopInputFormatter.format(court.basePricePerHour);
        _slotDuration = court.slotDuration;
      }
      if (parts.contains(CourtCopyPart.rates)) _rates = [...court.rates];
    });
    final copied = [
      if (parts.contains(CourtCopyPart.schedule)) 'horario',
      if (parts.contains(CourtCopyPart.pricing)) 'precio',
      if (parts.contains(CourtCopyPart.rates)) 'tarifas',
    ];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Copiado de "${court.name}": ${copied.join(', ')}.'),
        ),
      );
  }

  Future<void> _editRate([int? index]) async {
    final rate = await showCourtRateEditor(
      context,
      initial: index == null ? null : _rates[index],
      others: [
        for (final (i, r) in _rates.indexed)
          if (i != index) r,
      ],
    );
    if (rate == null || !mounted) return;
    setState(() {
      _rates = index == null
          ? [..._rates, rate]
          : ([..._rates]..[index] = rate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtFormBloc, CourtFormState>(
      builder: (context, state) {
        final busy = state.submitStatus.isBusy;
        // Con la cancha ya creada solo faltan fotos: el resto queda fijo.
        final locked = busy || state.pendingCourt != null;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideBreakpoint;
            final gutter = isWide ? 24.0 : 16.0;
            final heading = _Heading(
              title: _isEditing ? 'Editar cancha' : 'Nueva Cancha',
              venueName: state.venueName,
              onCopy: state.copySources.isEmpty || locked
                  ? null
                  : () => _copyFrom(state.copySources),
            );
            final banner = _planBanner(context, state);
            final basics = _basicSection(state, locked: locked, busy: busy);
            final booking = _lockable(
              locked,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _bookingSections(),
              ),
            );
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 24),
                    child: isWide
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: heading),
                                  if (banner != null) ...[
                                    const SizedBox(width: 24),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 420,
                                      ),
                                      child: banner,
                                    ),
                                  ],
                                ],
                              ),
                              ..._pendingNotice(state),
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: basics,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: booking),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heading,
                              if (banner != null) ...[
                                const SizedBox(height: 16),
                                banner,
                              ],
                              ..._pendingNotice(state),
                              const SizedBox(height: 24),
                              ...basics,
                              const SizedBox(height: 24),
                              booking,
                            ],
                          ),
                  ),
                ),
                _SaveBar(
                  isEditing: _isEditing,
                  alignEnd: isWide,
                  status: state.submitStatus,
                  progress: state.photoProgress,
                  retryPhotos: state.pendingCourt != null,
                  missing: busy ? const [] : _missing,
                  onSave: busy || _missing.isNotEmpty
                      ? null
                      : () => _submit(state),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget? _planBanner(BuildContext context, CourtFormState state) {
    if (!state.planKnown) return null;
    final plan = state.subscription;
    if (plan == null || !plan.isActive) {
      return CourtPlanLimitBanner(
        courtsInUse: 0,
        courtLimit: 0,
        noActivePlan: true,
        onUpgradePlan: () => context.go(AppRoutes.businessSettings),
      );
    }
    // Con el plan más alto no se ofrece mejorar.
    final next = plan.nextPlanName;
    return CourtPlanLimitBanner(
      courtsInUse: plan.courtsInUse,
      courtLimit: plan.courtLimit,
      planName: plan.planName,
      onUpgradePlan: next == null ? null : () => openPlanUpgrade(context, next),
      upgradeLabel: next == null
          ? 'Mejorar plan de suscripción'
          : 'Cambiar al plan $next',
    );
  }

  List<Widget> _pendingNotice(CourtFormState state) {
    final court = state.pendingCourt;
    if (court == null) return const [];
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.brandTealLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.brandTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'La cancha "${court.name}" ya se creó. Solo faltan fotos por '
                'subir: cambia las marcadas en rojo si hace falta y toca '
                '"Reintentar fotos".',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.brandTealDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static Widget _lockable(bool locked, Widget child) => IgnorePointer(
    ignoring: locked,
    child: AnimatedOpacity(
      opacity: locked ? 0.55 : 1,
      duration: const Duration(milliseconds: 150),
      child: child,
    ),
  );

  /// Sección 1: nombre, deporte, estructura, fotos y estado.
  List<Widget> _basicSection(
    CourtFormState state, {
    required bool locked,
    required bool busy,
  }) => [
    const CourtSectionHeader(number: 1, title: 'Datos Básicos'),
    const SizedBox(height: 12),
    _lockable(
      locked,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  key: const Key('court-name'),
                  controller: _name,
                  label: 'Nombre de la cancha',
                  prefixIcon: Icons.edit_outlined,
                  hintText: 'Ej: Cancha 1, Cancha Principal...',
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(CourtDraft.maxNameLength),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Nombre visible para tus clientes y el equipo de recepción. '
                  'No puede repetirse entre tus canchas.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CourtSportSelector(
            selectedSportId: _sport?.apiCode,
            onSportSelected: (option) =>
                _selectSport(option.sport, state.courtSurfaces),
          ),
          const SizedBox(height: 14),
          CourtStructureSelector(
            isCovered: _isCovered,
            onChanged: (covered) => setState(() => _isCovered = covered),
          ),
          const SizedBox(height: 14),
          CourtSpecsCard(
            surfaces: _surfacesFor(state),
            selectedSurface: _surface?.code,
            sportChosen: _sport != null,
            onSurfaceChanged: (surface) => setState(() => _surface = surface),
            lengthController: _length,
            widthController: _width,
            playersController: _players,
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    // Las fotos siguen editables tras crear la cancha (para reintentar).
    CourtPhotosPicker(
      photos: {
        for (final MapEntry(:key, :value) in _photos.entries) key: value.bytes,
      },
      // Al crear solo se piden la principal y una segunda opcional.
      secondSlot: _isEditing ? null : _secondSlot,
      onSecondSlotChanged: _changeSecondSlot,
      remotePhotos: _remotePhotos,
      failed: state.failedPhotos,
      enabled: !busy,
      onPick: _pickPhoto,
      // Quita la foto elegida y también la que ya estaba subida.
      onRemove: (slot) => setState(() {
        _photos.remove(slot);
        _remotePhotos.remove(slot);
      }),
    ),
    const SizedBox(height: 14),
    _lockable(
      locked,
      _ActiveCard(
        value: _isActive && state.canActivate,
        canActivate: state.canActivate,
        onChanged: (value) => setState(() => _isActive = value),
      ),
    ),
  ];

  /// Horario, precio y tarifas: cómo y cuánto se reserva.
  List<Widget> _bookingSections() => [
    const CourtSectionHeader(number: 2, title: 'Horario Semanal'),
    const SizedBox(height: 12),
    CourtWeeklySchedule(
      schedules: _schedules,
      onChanged: (value) => setState(() => _schedules = value),
    ),
    const SizedBox(height: 24),
    CourtSectionHeader(
      number: 3,
      title: 'Precio y tarifas',
      trailing: Text(
        _rates.length == 1 ? '1 tarifa' : '${_rates.length} tarifas',
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ),
    const SizedBox(height: 12),
    CourtPricingCard(
      basePriceController: _basePrice,
      slotDuration: _slotDuration,
      onSlotDurationChanged: (value) => setState(() => _slotDuration = value),
    ),
    const SizedBox(height: 14),
    CourtRatesSection(
      rates: _rates,
      onAdd: _editRate,
      onEdit: _editRate,
      onRemove: (index) =>
          setState(() => _rates = [..._rates]..removeAt(index)),
    ),
  ];
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.value,
    required this.canActivate,
    required this.onChanged,
  });

  final bool value;
  final bool canActivate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.toggle_on_outlined,
              color: AppColors.brandTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancha activa para reservas',
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canActivate
                      ? 'Cuenta para el límite de canchas de tu plan.'
                      : 'Tu plan no permite más canchas activas: se creará '
                            'inactiva.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: canActivate ? onChanged : null,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.venueName,
    required this.onCopy,
  });

  final String title;

  final String? venueName;

  /// `null` si no hay canchas de las que copiar.
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final venue = venueName;
    final copy = onCopy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go(AppRoutes.businessCourts),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandTeal,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            textStyle: AppTypography.labelMd,
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Mis canchas'),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTypography.headlineLg.copyWith(
            color: AppColors.onSurface,
            letterSpacing: -0.24,
          ),
        ),
        if (venue != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.stadium_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  venue,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (copy != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('copy-from-court'),
            onPressed: copy,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandTeal,
              side: BorderSide(color: AppColors.brandTeal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: AppTypography.labelMd,
            ),
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Copiar horario y tarifas de otra cancha'),
          ),
        ],
      ],
    );
  }
}

/// Estado vacío o de error con una acción.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.brandTeal),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta blanca con sombra suave de las secciones del formulario.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// Barra inferior fija con "Guardar cancha", el avance de la subida y lo
/// que falta completar. En web el botón queda a la derecha con ancho acotado.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.alignEnd,
    required this.status,
    required this.progress,
    required this.retryPhotos,
    required this.missing,
    required this.onSave,
    this.isEditing = false,
  });

  final bool isEditing;

  final bool alignEnd;
  final CourtFormSubmitStatus status;
  final (int, int) progress;
  final bool retryPhotos;
  final List<String> missing;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      CourtFormSubmitStatus.saving =>
        isEditing ? 'Guardando cambios…' : 'Creando cancha…',
      CourtFormSubmitStatus.uploadingPhotos =>
        'Actualizando fotos ${progress.$1}/${progress.$2}…',
      _ when retryPhotos => 'Reintentar fotos',
      _ => isEditing ? 'Guardar cambios' : 'Guardar cancha',
    };
    final button = FilledButton.icon(
      key: const Key('btn-save-court'),
      onPressed: onSave,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.surfaceContainerHighest,
        foregroundColor: AppColors.onPrimary,
        disabledForegroundColor: AppColors.onSurfaceVariant,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.headlineSm.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      icon: status.isBusy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onSurfaceVariant,
              ),
            )
          : Icon(
              retryPhotos ? Icons.refresh_rounded : Icons.check_circle_outline,
              size: 22,
            ),
      label: Text(label),
    );
    final hint = missing.isEmpty
        ? null
        : Text(
            'Falta: ${missing.join(', ')}',
            key: const Key('court-missing'),
            textAlign: alignEnd ? TextAlign.end : TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Color(0x1417231C),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: alignEnd ? 24 : 16,
            vertical: 12,
          ),
          child: alignEnd
              ? Row(
                  children: [
                    Expanded(child: hint ?? const SizedBox.shrink()),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: button),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hint != null) ...[hint, const SizedBox(height: 8)],
                    button,
                  ],
                ),
        ),
      ),
    );
  }
}
