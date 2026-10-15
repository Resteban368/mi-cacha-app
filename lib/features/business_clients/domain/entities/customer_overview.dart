import 'package:equatable/equatable.dart';

/// Resumen global de métricas del módulo de clientes para el negocio.
class CustomerOverview extends Equatable {
  const CustomerOverview({
    this.totalCustomers = 0,
    this.newThisMonth = 0,
    this.newVsLastMonthPct,
    this.loyalCustomers = 0,
    this.loyalPct,
    this.totalReservations = 0,
    this.pendingBalance = 0,
    this.currency = 'COP',
  });

  factory CustomerOverview.fromJson(Map<String, dynamic> json) {
    return CustomerOverview(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      newThisMonth: (json['newThisMonth'] as num?)?.toInt() ?? 0,
      newVsLastMonthPct: (json['newVsLastMonthPct'] as num?)?.toDouble(),
      loyalCustomers: (json['loyalCustomers'] as num?)?.toInt() ?? 0,
      loyalPct: (json['loyalPct'] as num?)?.toDouble(),
      totalReservations: (json['totalReservations'] as num?)?.toInt() ?? 0,
      pendingBalance: (json['pendingBalance'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'COP',
    );
  }

  final int totalCustomers;
  final int newThisMonth;
  final double? newVsLastMonthPct;
  final int loyalCustomers;
  final double? loyalPct;
  final int totalReservations;
  final int pendingBalance;
  final String currency;

  Map<String, dynamic> toJson() => {
    'totalCustomers': totalCustomers,
    'newThisMonth': newThisMonth,
    'newVsLastMonthPct': newVsLastMonthPct,
    'loyalCustomers': loyalCustomers,
    'loyalPct': loyalPct,
    'totalReservations': totalReservations,
    'pendingBalance': pendingBalance,
    'currency': currency,
  };

  CustomerOverview copyWith({
    int? totalCustomers,
    int? newThisMonth,
    double? newVsLastMonthPct,
    int? loyalCustomers,
    double? loyalPct,
    int? totalReservations,
    int? pendingBalance,
    String? currency,
  }) {
    return CustomerOverview(
      totalCustomers: totalCustomers ?? this.totalCustomers,
      newThisMonth: newThisMonth ?? this.newThisMonth,
      newVsLastMonthPct: newVsLastMonthPct ?? this.newVsLastMonthPct,
      loyalCustomers: loyalCustomers ?? this.loyalCustomers,
      loyalPct: loyalPct ?? this.loyalPct,
      totalReservations: totalReservations ?? this.totalReservations,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [
    totalCustomers,
    newThisMonth,
    newVsLastMonthPct,
    loyalCustomers,
    loyalPct,
    totalReservations,
    pendingBalance,
    currency,
  ];
}
