import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'image_upload.dart';
import 'photo_picker.dart';

/// Pide una foto al usuario: en web abre el selector de archivos; en el
/// celular primero pregunta si usar la galería o la cámara.
///
/// Devuelve `null` si canceló. Si el selector falla (permiso denegado,
/// cámara no disponible, plugin sin registrar) avisa con un SnackBar en vez
/// de fallar en silencio.
Future<ImageUpload?> pickImageUpload(
  BuildContext context,
  PhotoPicker picker,
) async {
  final source = kIsWeb ? PhotoSource.gallery : await _askSource(context);
  if (source == null || !context.mounted) return null;
  final PickedPhoto? photo;
  try {
    photo = await picker.pick(source);
  } catch (error, stack) {
    debugPrint('No se pudo elegir la foto: $error\n$stack');
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            source == PhotoSource.camera
                ? 'No pudimos abrir la cámara. Revisa los permisos.'
                : 'No pudimos abrir tus fotos. Revisa los permisos.',
          ),
          backgroundColor: AppColors.statusDue,
        ),
      );
    return null;
  }
  if (photo == null) return null;
  return ImageUpload(bytes: photo.bytes, fileName: photo.name);
}

Future<PhotoSource?> _askSource(BuildContext context) =>
    showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
