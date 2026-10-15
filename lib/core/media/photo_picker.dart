import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { gallery, camera }

/// Foto elegida por el usuario, ya comprimida.
typedef PickedPhoto = ({Uint8List bytes, String name});

/// Elige una foto de la galería o la cámara. Interfaz propia para poder
/// reemplazarla en los tests.
abstract interface class PhotoPicker {
  /// `null` si el usuario canceló.
  Future<PickedPhoto?> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Se reduce al elegir para no pasar del límite de 4 MB de la API; con
  /// calidad < 100 la foto sale en JPG (también las HEIC de iOS).
  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        PhotoSource.gallery => ImageSource.gallery,
        PhotoSource.camera => ImageSource.camera,
      },
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return (bytes: await file.readAsBytes(), name: file.name);
  }
}
