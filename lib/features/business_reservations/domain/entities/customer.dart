import 'package:equatable/equatable.dart';

/// Cliente del negocio.
class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.documentId,
  });

  final String id;
  final String name;
  final String phone;
  final String documentId;

  @override
  List<Object?> get props => [id, name, phone, documentId];
}

/// Datos de un cliente nuevo, con las reglas de la API.
class NewCustomer extends Equatable {
  const NewCustomer({
    required this.name,
    required this.phone,
    required this.documentId,
  });

  static final _phone = RegExp(r'^\+?[\d\s()-]{7,20}$');
  static final _document = RegExp(r'^[\dA-Za-z.\s-]{4,20}$');

  final String name;
  final String phone;
  final String documentId;

  static String? validateName(String value) {
    final name = value.trim();
    if (name.length < 2) return 'Ingresa el nombre (mínimo 2 letras).';
    if (name.length > 100) return 'Máximo 100 caracteres.';
    return null;
  }

  static String? validatePhone(String value) => _phone.hasMatch(value.trim())
      ? null
      : 'Teléfono de 7 a 20 dígitos (puede llevar espacios, - o +).';

  static String? validateDocument(String value) =>
      _document.hasMatch(value.trim())
      ? null
      : 'Cédula de 4 a 20 caracteres (letras, números, puntos o guiones).';

  /// Primer error, o `null` si los tres datos son válidos.
  String? get error =>
      validateName(name) ??
      validatePhone(phone) ??
      validateDocument(documentId);

  @override
  List<Object?> get props => [name, phone, documentId];
}
