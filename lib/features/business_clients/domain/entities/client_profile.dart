import 'package:equatable/equatable.dart';

import 'customer_metrics.dart';

/// Nivel de fidelidad y actividad del cliente en el centro deportivo.
enum ClientTier {
  vip('VIP Diamante', 'Cliente estrella con alta frecuencia y puntualidad'),
  frecuente('Frecuente', 'Más de 5 reservas realizadas'),
  recurrente('Recurrente', 'Entre 2 y 5 reservas realizadas'),
  nuevo('Nuevo', 'Primera reserva o recién registrado');

  const ClientTier(this.label, this.description);

  final String label;
  final String description;

  static ClientTier fromString(String? level) {
    switch (level?.toUpperCase()) {
      case 'VIP':
        return ClientTier.vip;
      case 'FRECUENTE':
        return ClientTier.frecuente;
      case 'RECURRENTE':
        return ClientTier.recurrente;
      case 'NUEVO':
      default:
        return ClientTier.nuevo;
    }
  }
}

/// Perfil enriquecido de un cliente/jugador del negocio para el módulo web y móvil.
class ClientProfile extends Equatable {
  const ClientProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.documentId,
    this.email,
    this.tier = ClientTier.nuevo,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.noShows = 0,
    this.totalSpentCop = 0,
    this.pendingDebtCop = 0,
    this.lastBookingDate,
    this.lastCourtName,
    this.preferredSport = 'Fútbol',
    this.notes = '',
    this.tags = const [],
    this.createdAt,
    this.metrics,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    CustomerMetrics? metrics;
    if (json['metrics'] is Map<String, dynamic>) {
      metrics = CustomerMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>,
      );
    }

    final tier = metrics != null
        ? ClientTier.fromString(metrics.level)
        : ClientTier.nuevo;

    DateTime? createdAt;
    final createdStr = json['createdAt'] as String?;
    if (createdStr != null && createdStr.isNotEmpty) {
      createdAt = DateTime.tryParse(createdStr)?.toLocal();
    }

    final sport =
        (json['preferredSport'] as String?) ??
        metrics?.favoriteSport ??
        'Fútbol';

    return ClientProfile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      documentId: (json['documentId'] as String?) ?? '',
      email: json['email'] as String?,
      tier: tier,
      totalBookings: metrics?.reservations ?? 0,
      completedBookings: metrics?.reservations ?? 0,
      totalSpentCop: metrics?.totalSpent ?? 0,
      pendingDebtCop: metrics?.balance ?? 0,
      lastBookingDate: metrics?.lastVisitDate,
      lastCourtName: metrics?.lastVisitCourtName,
      preferredSport: sport,
      notes: (json['notes'] as String?) ?? '',
      createdAt: createdAt,
      metrics: metrics,
    );
  }

  final String id;
  final String name;
  final String phone;
  final String documentId;
  final String? email;
  final ClientTier tier;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int noShows;
  final int totalSpentCop;
  final int pendingDebtCop;
  final DateTime? lastBookingDate;
  final String? lastCourtName;
  final String preferredSport;
  final String notes;
  final List<String> tags;
  final DateTime? createdAt;
  final CustomerMetrics? metrics;

  /// Tasa de asistencia porcentual (0 - 100).
  double get attendanceRate {
    if (metrics?.attendancePct != null) {
      return metrics!.attendancePct!;
    }
    if (totalBookings == 0) return 100.0;
    final attended = completedBookings > 0
        ? completedBookings
        : (totalBookings - cancelledBookings - noShows);
    final rate = (attended / totalBookings) * 100;
    return rate.clamp(0.0, 100.0);
  }

  /// Limpieza de teléfono para links de WhatsApp (+57...).
  String get cleanPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('57') && digits.length >= 12) return digits;
    if (digits.length == 10 && digits.startsWith('3')) return '57$digits';
    return digits;
  }

  /// URL lista para abrir conversación en WhatsApp Web / App.
  String get whatsAppUrl {
    final number = cleanPhone;
    final encodedMsg = Uri.encodeComponent(
      '¡Hola $name! Te escribimos de Mi Cancha sobre tus reservas deportivas.',
    );
    return 'https://wa.me/$number?text=$encodedMsg';
  }

  /// Iniciales para el avatar (ej: "Juan Pérez" -> "JP").
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CL';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get hasDebt => pendingDebtCop > 0;
  bool get isVip => tier == ClientTier.vip;
  bool get isFrequent => tier == ClientTier.frecuente || tier == ClientTier.vip;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'documentId': documentId,
    'email': email,
    'preferredSport': preferredSport,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
    'metrics': metrics?.toJson(),
  };

  ClientProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? documentId,
    String? email,
    ClientTier? tier,
    int? totalBookings,
    int? completedBookings,
    int? cancelledBookings,
    int? noShows,
    int? totalSpentCop,
    int? pendingDebtCop,
    DateTime? lastBookingDate,
    String? lastCourtName,
    String? preferredSport,
    String? notes,
    List<String>? tags,
    DateTime? createdAt,
    CustomerMetrics? metrics,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      documentId: documentId ?? this.documentId,
      email: email ?? this.email,
      tier: tier ?? this.tier,
      totalBookings: totalBookings ?? this.totalBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      noShows: noShows ?? this.noShows,
      totalSpentCop: totalSpentCop ?? this.totalSpentCop,
      pendingDebtCop: pendingDebtCop ?? this.pendingDebtCop,
      lastBookingDate: lastBookingDate ?? this.lastBookingDate,
      lastCourtName: lastCourtName ?? this.lastCourtName,
      preferredSport: preferredSport ?? this.preferredSport,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      metrics: metrics ?? this.metrics,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    documentId,
    email,
    tier,
    totalBookings,
    completedBookings,
    cancelledBookings,
    noShows,
    totalSpentCop,
    pendingDebtCop,
    lastBookingDate,
    lastCourtName,
    preferredSport,
    notes,
    tags,
    createdAt,
    metrics,
  ];
}
