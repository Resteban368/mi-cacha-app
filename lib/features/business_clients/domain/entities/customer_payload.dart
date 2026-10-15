import 'package:equatable/equatable.dart';

/// Payload para crear o actualizar un cliente del negocio.
class CustomerPayload extends Equatable {
  const CustomerPayload({
    required this.name,
    required this.phone,
    required this.documentId,
    this.preferredSport,
    this.notes,
  });

  final String name;
  final String phone;
  final String documentId;
  final String? preferredSport;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'phone': phone.trim(),
    'documentId': documentId.trim(),
    if (preferredSport != null && preferredSport!.isNotEmpty)
      'preferredSport': preferredSport
    else
      'preferredSport': null,
    if (notes != null && notes!.isNotEmpty) 'notes': notes else 'notes': null,
  };

  @override
  List<Object?> get props => [name, phone, documentId, preferredSport, notes];
}
