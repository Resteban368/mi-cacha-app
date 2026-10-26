import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/device_location.dart';
import '../../../../core/location/geo_point.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/media/pick_image.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/business.dart';
import '../bloc/business_city_cubit.dart';
import '../bloc/business_profile_bloc.dart';
import '../widgets/amenity_chips.dart';
import 'location_picker_page.dart';
import '../widgets/business_form_label.dart';
import '../widgets/business_city_fields.dart';
import '../widgets/business_media_fields.dart';
import '../widgets/online_booking_card.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../business_setup/presentation/business_setup_gate.dart';

/// Sección "Mi negocio". Sin negocio creado muestra el formulario
/// "Registra tu sede deportiva" (diseño "Crear Negocio (Estado Vacío)");
/// con negocio, el mismo formulario precargado para editarlo.
class BusinessProfilePage extends StatelessWidget {
  const BusinessProfilePage({
    super.key,
    required this.photoPicker,
    required this.deviceLocation,
    this.mapTileProvider,
  });

  final PhotoPicker photoPicker;
  final DeviceLocation deviceLocation;

  /// Solo para tests (teselas del mapa sin red).
  final TileProvider? mapTileProvider;

  @override
  Widget build(BuildContext context) {
    // Al cargar: diálogo con el ícono de la app sobre el fondo difuminado.
    return BlocLoadingDialog<BusinessProfileBloc, BusinessProfileState>(
      isLoading: (s) =>
          s.status == BusinessProfileStatus.initial ||
          s.status == BusinessProfileStatus.loading,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BusinessProfileBloc, BusinessProfileState>(
          listenWhen: (prev, curr) => prev.saveStatus != curr.saveStatus,
          listener: _onSaveStatus,
        ),
        BlocListener<BusinessProfileBloc, BusinessProfileState>(
          listenWhen: (prev, curr) => prev.photoStatus != curr.photoStatus,
          listener: _onPhotoStatus,
        ),
      ],
      child: Column(
        children: [
          const AppTopBar(
            title: 'Mi negocio',
            subtitle: 'Datos y ubicación de tu sede',
            icon: Icons.storefront_rounded,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: BlocBuilder<BusinessProfileBloc, BusinessProfileState>(
                buildWhen: (prev, curr) => prev.status != curr.status,
                builder: (context, state) => switch (state.status) {
                  BusinessProfileStatus.initial ||
                  BusinessProfileStatus.loading => const SizedBox.shrink(),
                  BusinessProfileStatus.failure => _LoadError(
                    onRetry: () => context.read<BusinessProfileBloc>().add(
                      const BusinessProfileRequested(),
                    ),
                  ),
                  BusinessProfileStatus.ready => _BusinessForm(
                    initial: state.business,
                    photoPicker: photoPicker,
                    deviceLocation: deviceLocation,
                    mapTileProvider: mapTileProvider,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSaveStatus(BuildContext context, BusinessProfileState state) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (state.saveStatus
        case BusinessSaveStatus.created || BusinessSaveStatus.updated) {
      // Puede completar el paso "negocio" de la configuración inicial.
      BusinessSetupScope.refresh(context);
    }
    switch (state.saveStatus) {
      case BusinessSaveStatus.created:
        final coverFailed = state.photoStatus == BusinessPhotoStatus.failure;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              coverFailed
                  ? 'Negocio registrado, pero no pudimos subir la foto. '
                        'Súbela desde Mi negocio.'
                  : 'Negocio registrado',
            ),
          ),
        );
        // Siguiente paso del alta: registrar las canchas.
        context.go(AppRoutes.businessCourts);
      case BusinessSaveStatus.updated:
        messenger.showSnackBar(
          const SnackBar(content: Text('Cambios guardados')),
        );
      case BusinessSaveStatus.failure:
        messenger.showSnackBar(
          SnackBar(
            content: Text('No pudimos guardar el negocio. Intenta de nuevo.'),
            backgroundColor: AppColors.statusDue,
          ),
        );
      case BusinessSaveStatus.idle || BusinessSaveStatus.saving:
        break;
    }
  }

  void _onPhotoStatus(BuildContext context, BusinessProfileState state) {
    // Al registrar el negocio el aviso lo da _onSaveStatus.
    if (state.isSaving) return;
    if (state.photoStatus
        case BusinessPhotoStatus.uploaded || BusinessPhotoStatus.removed) {
      BusinessSetupScope.refresh(context);
    }
    final (message, isError) = switch (state.photoStatus) {
      BusinessPhotoStatus.uploaded => ('Foto agregada', false),
      BusinessPhotoStatus.removed => ('Foto eliminada', false),
      BusinessPhotoStatus.reordered => ('Orden de fotos actualizado', false),
      BusinessPhotoStatus.tooLarge => (
        'La foto supera los 4 MB. Elige una más liviana.',
        true,
      ),
      BusinessPhotoStatus.invalidType => ('La foto debe ser JPG o PNG.', true),
      BusinessPhotoStatus.limitReached => (
        'Ya tienes ${Business.maxPhotos} fotos. Elimina una para agregar '
            'otra.',
        true,
      ),
      BusinessPhotoStatus.failure => (
        'No pudimos actualizar las fotos. Intenta de nuevo.',
        true,
      ),
      BusinessPhotoStatus.idle ||
      BusinessPhotoStatus.uploading ||
      BusinessPhotoStatus.removing ||
      BusinessPhotoStatus.reordering => (null, false),
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.statusDue : null,
        ),
      );
  }
}

class _BusinessForm extends StatefulWidget {
  const _BusinessForm({
    required this.initial,
    required this.photoPicker,
    required this.deviceLocation,
    required this.mapTileProvider,
  });

  /// Negocio existente a editar; `null` en el estado vacío (crear).
  final Business? initial;
  final PhotoPicker photoPicker;
  final DeviceLocation deviceLocation;
  final TileProvider? mapTileProvider;

  @override
  State<_BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends State<_BusinessForm> {
  /// Desde este ancho el formulario se reparte en dos columnas (web).
  static const _wideBreakpoint = 900.0;

  late final _name = TextEditingController(text: widget.initial?.name);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _neighborhood = TextEditingController(
    text: widget.initial?.neighborhood,
  );
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _amenities = ValueNotifier<Set<String>>({
    ...?widget.initial?.amenities,
  });
  late final _location = ValueNotifier<GeoPoint?>(widget.initial?.location);

  bool get _isEditing => widget.initial != null;

  BusinessDraft get _draft => BusinessDraft(
    cityId: context.read<BusinessCityCubit>().state.city?.id,
    name: _name.text,
    address: _address.text,
    neighborhood: _neighborhood.text,
    description: _description.text,
    amenities: _amenities.value,
    location: _location.value,
  );

  @override
  void initState() {
    super.initState();
    // Al editar quedan elegidos el departamento y la ciudad actuales.
    context.read<BusinessCityCubit>().load(initial: widget.initial?.city);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _neighborhood.dispose();
    _description.dispose();
    _amenities.dispose();
    _location.dispose();
    super.dispose();
  }

  void _toggleAmenity(String amenity) {
    final next = {..._amenities.value};
    if (!next.remove(amenity)) next.add(amenity);
    _amenities.value = next;
  }

  void _submit() {
    if (!ensureCanWrite(context)) return;
    FocusScope.of(context).unfocus();
    // Al crear, departamento y ciudad son obligatorios (la API los exige).
    // Al editar, sin ciudad se conserva la actual.
    final cityOk = context.read<BusinessCityCubit>().validate();
    if (!_isEditing && !cityOk) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Elige el departamento y la ciudad del negocio.'),
            backgroundColor: AppColors.statusDue,
          ),
        );
      return;
    }
    context.read<BusinessProfileBloc>().add(BusinessProfileSaved(_draft));
  }

  Future<void> _addPhoto() async {
    if (!ensureCanWrite(context)) return;
    final image = await pickImageUpload(context, widget.photoPicker);
    if (image == null || !mounted) return;
    context.read<BusinessProfileBloc>().add(BusinessPhotoPicked(image));
  }

  Future<void> _removePhoto(BusinessPhoto photo) async {
    if (!ensureCanWrite(context)) return;
    final bloc = context.read<BusinessProfileBloc>();
    final isCover = bloc.state.business?.photos.firstOrNull?.id == photo.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta foto?'),
        content: Text(
          isCover
              ? 'Es la portada: la siguiente foto pasará a ser la portada.'
              : 'La foto se quitará de la galería de tu sede.',
        ),
        actions: [
          TextButton(
            key: const Key('photo-remove-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('photo-remove-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusDue),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    bloc.add(BusinessPhotoRemoved(photo.id));
  }

  void _reorderPhotos(List<String> ids) {
    if (!ensureCanWrite(context)) return;
    context.read<BusinessProfileBloc>().add(BusinessPhotosReordered(ids));
  }

  /// Abre el mapa a pantalla completa (por encima del menú lateral). La
  /// ubicación se guarda junto con el resto al tocar "Guardar".
  Future<void> _pickLocation() async {
    if (!ensureCanWrite(context)) return;
    final point = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<GeoPoint>(
        fullscreenDialog: true,
        builder: (_) => LocationPickerPage(
          deviceLocation: widget.deviceLocation,
          initial: _location.value,
          tileProvider: widget.mapTileProvider,
        ),
      ),
    );
    if (point == null || !mounted) return;
    _location.value = point;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Ubicación fijada. Toca "Guardar cambios" para aplicarla.'
                : 'Ubicación fijada.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        final gutter = isWide ? 24.0 : 16.0;
        final cover = BlocBuilder<BusinessProfileBloc, BusinessProfileState>(
          buildWhen: (prev, curr) =>
              prev.business?.photos != curr.business?.photos ||
              prev.pendingPhoto != curr.pendingPhoto ||
              prev.photoStatus != curr.photoStatus,
          builder: (context, state) => BusinessPhotoGallery(
            photos: state.business?.photos ?? const [],
            pendingBytes: state.pendingPhoto?.bytes,
            status: state.photoStatus,
            onAdd: _addPhoto,
            onRemove: _removePhoto,
            onRemovePending: () => context.read<BusinessProfileBloc>().add(
              const BusinessPhotoRemoved(),
            ),
            onReorder: _reorderPhotos,
          ),
        );
        final location = ValueListenableBuilder(
          valueListenable: _location,
          builder: (_, point, _) => LocationField(
            location: point,
            tileProvider: widget.mapTileProvider,
            onPinTap: _pickLocation,
            onClear: () => _location.value = null,
          ),
        );
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
                children: [
                  _Heading(isEditing: _isEditing),
                  const SizedBox(height: 24),
                  // El link existe solo con el negocio registrado.
                  if (_isEditing) ...[
                    BlocBuilder<BusinessProfileBloc, BusinessProfileState>(
                      buildWhen: (prev, curr) =>
                          prev.bookingLink != curr.bookingLink ||
                          prev.bookingLinkStatus != curr.bookingLinkStatus,
                      builder: (context, state) => OnlineBookingCard(
                        status: state.bookingLinkStatus,
                        link: state.bookingLink,
                        businessName: state.business?.name,
                        onRetry: () => context.read<BusinessProfileBloc>().add(
                          const BusinessOnlineBookingRequested(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._dataFields(),
                              const SizedBox(height: 24),
                              ..._profileFields(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              cover,
                              const SizedBox(height: 24),
                              location,
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    cover,
                    const SizedBox(height: 24),
                    ..._dataFields(),
                    const SizedBox(height: 24),
                    location,
                    const SizedBox(height: 24),
                    ..._profileFields(),
                  ],
                ],
              ),
            ),
            _SaveBar(
              fields: Listenable.merge([_name, _address, _neighborhood]),
              canSave: () => _draft.isComplete,
              label: _isEditing
                  ? 'Guardar cambios'
                  : 'Guardar negocio y continuar',
              alignEnd: isWide,
              onSave: _submit,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _dataFields() => [
    AppTextField(
      label: 'Nombre del negocio o sede deportiva',
      prefixIcon: Icons.stadium_outlined,
      controller: _name,
      hintText: 'Ej: Complejo Deportivo El Campín',
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [LengthLimitingTextInputFormatter(80)],
    ),
    const SizedBox(height: 16),
    BusinessCityFields(
      // Negocio anterior sin ciudad: se pide completarla.
      showMissingNotice: _isEditing && widget.initial?.city == null,
    ),
    const SizedBox(height: 16),
    AppTextField(
      label: 'Dirección física',
      prefixIcon: Icons.signpost_outlined,
      controller: _address,
      hintText: 'Ej: Carrera 11 # 18-45',
      textInputAction: TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(120)],
    ),
    const SizedBox(height: 16),
    AppTextField(
      label: 'Barrio o sector',
      prefixIcon: Icons.apartment_outlined,
      controller: _neighborhood,
      hintText: 'Ej: Juan XXIII, Centro, La Salle',
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [LengthLimitingTextInputFormatter(80)],
    ),
  ];

  List<Widget> _profileFields() => [
    BusinessFormLabel(
      'Descripción de la sede',
      trailing: Text(
        'Para el perfil de reservas',
        textAlign: TextAlign.end,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ),
    const SizedBox(height: 6),
    _DescriptionField(controller: _description),
    const SizedBox(height: 24),
    const BusinessFormLabel('Servicios e instalaciones incluidas'),
    const SizedBox(height: 10),
    BlocBuilder<BusinessProfileBloc, BusinessProfileState>(
      buildWhen: (prev, curr) =>
          prev.amenityStatus != curr.amenityStatus ||
          prev.amenityOptions != curr.amenityOptions,
      builder: (context, state) => ValueListenableBuilder(
        valueListenable: _amenities,
        builder: (_, selected, _) => AmenityChips(
          options: state.amenityOptions,
          status: state.amenityStatus,
          selected: selected,
          onToggle: _toggleAmenity,
          onRetry: () => context.read<BusinessProfileBloc>().add(
            const BusinessAmenitiesRequested(),
          ),
        ),
      ),
    ),
  ];
}

class _Heading extends StatelessWidget {
  const _Heading({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            isEditing ? 'Tu sede deportiva' : 'Registra tu sede deportiva',
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEditing
              ? 'Mantén al día los datos que ven tus clientes al reservar.'
              : 'Gestiona tus reservas, canchas y cobros en un solo lugar '
                    'con control total de caja.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Área de texto multilínea con el mismo estilo de los campos de la app.
class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return Semantics(
      label: 'Descripción de la sede',
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(500)],
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        cursorColor: AppColors.brandTeal,
        decoration: InputDecoration(
          hintText:
              'Describe las canchas, servicios y ventajas de tu sede '
              'deportiva...',
          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
          filled: true,
          fillColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? AppColors.surfaceContainerLowest
                : AppColors.slate50,
          ),
          contentPadding: const EdgeInsets.all(14),
          border: border(AppColors.slate200),
          enabledBorder: border(AppColors.slate200),
          focusedBorder: border(AppColors.brandTeal, 2),
        ),
      ),
    );
  }
}

/// Barra inferior con el botón principal; se habilita cuando nombre,
/// dirección y barrio están completos. Solo ella se redibuja al escribir.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.fields,
    required this.canSave,
    required this.label,
    required this.alignEnd,
    required this.onSave,
  });

  final Listenable fields;
  final bool Function() canSave;
  final String label;

  /// En web el botón no se estira: queda a la derecha.
  final bool alignEnd;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final button = ListenableBuilder(
      listenable: fields,
      builder: (context, _) =>
          BlocBuilder<BusinessProfileBloc, BusinessProfileState>(
            buildWhen: (p, c) => p.isSaving != c.isSaving,
            builder: (context, state) {
              final enabled = canSave() && !state.isSaving;
              return FilledButton(
                onPressed: enabled ? onSave : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandTeal,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: state.isSaving
                      ? AppColors.brandTeal
                      : AppColors.surfaceContainerHigh,
                  disabledForegroundColor: state.isSaving
                      ? AppColors.onPrimary
                      : AppColors.outline,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTypography.labelLg,
                ),
                child: state.isSaving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              );
            },
          ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1413211E),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            alignEnd ? 24 : 16,
            12,
            alignEnd ? 24 : 16,
            12,
          ),
          child: alignEnd
              ? Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(width: 360, child: button),
                )
              : button,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.brandTeal,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar tu negocio',
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
