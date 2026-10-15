import 'package:equatable/equatable.dart';

/// Métricas individuales de comportamiento y valor de un cliente.
class CustomerMetrics extends Equatable {
  const CustomerMetrics({
    this.reservations = 0,
    this.level = 'NUEVO',
    this.attendancePct,
    this.totalSpent = 0,
    this.balance = 0,
    this.lastVisitDate,
    this.lastVisitCourtName,
    this.favoriteSport,
  });

  factory CustomerMetrics.fromJson(Map<String, dynamic> json) {
    DateTime? lastDate;
    String? courtName;

    final lastVisit = json['lastVisit'];
    if (lastVisit is Map<String, dynamic>) {
      final dateStr = lastVisit['date'] as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        lastDate = DateTime.tryParse(dateStr)?.toLocal();
      }
      courtName = lastVisit['courtName'] as String?;
    }

    return CustomerMetrics(
      reservations: (json['reservations'] as num?)?.toInt() ?? 0,
      level: (json['level'] as String?) ?? 'NUEVO',
      attendancePct: (json['attendancePct'] as num?)?.toDouble(),
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      lastVisitDate: lastDate,
      lastVisitCourtName: courtName,
      favoriteSport: json['favoriteSport'] as String?,
    );
  }

  final int reservations;
  final String level;
  final double? attendancePct;
  final int totalSpent;
  final int balance;
  final DateTime? lastVisitDate;
  final String? lastVisitCourtName;
  final String? favoriteSport;

  Map<String, dynamic> toJson() => {
    'reservations': reservations,
    'level': level,
    'attendancePct': attendancePct,
    'totalSpent': totalSpent,
    'balance': balance,
    'lastVisit': {
      'date': lastVisitDate?.toIso8601String(),
      'courtName': lastVisitCourtName,
    },
    'favoriteSport': favoriteSport,
  };

  CustomerMetrics copyWith({
    int? reservations,
    String? level,
    double? attendancePct,
    int? totalSpent,
    int? balance,
    DateTime? lastVisitDate,
    String? lastVisitCourtName,
    String? favoriteSport,
  }) {
    return CustomerMetrics(
      reservations: reservations ?? this.reservations,
      level: level ?? this.level,
      attendancePct: attendancePct ?? this.attendancePct,
      totalSpent: totalSpent ?? this.totalSpent,
      balance: balance ?? this.balance,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      lastVisitCourtName: lastVisitCourtName ?? this.lastVisitCourtName,
      favoriteSport: favoriteSport ?? this.favoriteSport,
    );
  }

  @override
  List<Object?> get props => [
    reservations,
    level,
    attendancePct,
    totalSpent,
    balance,
    lastVisitDate,
    lastVisitCourtName,
    favoriteSport,
  ];
}
