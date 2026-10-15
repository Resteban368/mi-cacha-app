import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum ImageUploadError {
  /// Supera los 4 MB que acepta la API.
  tooLarge,

  /// No es JPG ni PNG.
  invalidType,
}

/// Imagen elegida por el usuario, lista para subir a la API (JPG o PNG).
///
/// Se maneja en bytes (no en ruta de archivo) para que funcione igual en
/// web, Android e iOS.
class ImageUpload extends Equatable {
  const ImageUpload({required this.bytes, required this.fileName});

  /// Límite de la API (Vercel corta los cuerpos en 4,5 MB).
  static const maxBytes = 4 * 1024 * 1024;

  static const _jpegMagic = [0xff, 0xd8, 0xff];
  static const _pngMagic = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

  final Uint8List bytes;
  final String fileName;

  bool get isPng => _startsWith(_pngMagic);

  /// El tipo se reconoce por la firma del archivo, igual que en la API.
  ImageUploadError? get error {
    if (bytes.length > maxBytes) return ImageUploadError.tooLarge;
    if (!_startsWith(_jpegMagic) && !isPng) return ImageUploadError.invalidType;
    return null;
  }

  bool _startsWith(List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  /// Bytes por identidad: comparar varios MB en cada `==` sería caro.
  @override
  List<Object?> get props => [identityHashCode(bytes), bytes.length, fileName];
}

class ImageUploadException implements Exception {
  const ImageUploadException(this.error);

  final ImageUploadError error;

  @override
  String toString() => 'ImageUploadException($error)';
}
