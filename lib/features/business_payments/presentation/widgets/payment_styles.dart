import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment.dart';

/// Nombre, ícono y colores de cada medio de pago (sin logos de marca).
extension PaymentMethodStyle on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.efectivo => 'Efectivo',
    PaymentMethod.nequi => 'Nequi',
    PaymentMethod.daviplata => 'Daviplata',
    PaymentMethod.bancolombiaQr => 'Bancolombia QR',
    PaymentMethod.breB => 'Bre-B',
    PaymentMethod.otro => 'Otro medio',
    PaymentMethod.transferencia => 'Transferencia',
  };

  IconData get icon => switch (this) {
    PaymentMethod.efectivo => Icons.payments_outlined,
    PaymentMethod.nequi => Icons.phone_iphone_rounded,
    PaymentMethod.daviplata => Icons.account_balance_wallet_outlined,
    PaymentMethod.bancolombiaQr => Icons.qr_code_2_rounded,
    PaymentMethod.breB => Icons.bolt_rounded,
    PaymentMethod.otro => Icons.more_horiz_rounded,
    PaymentMethod.transferencia => Icons.account_balance_outlined,
  };

  Color get color => switch (this) {
    PaymentMethod.efectivo => AppColors.emerald600,
    PaymentMethod.nequi => const Color(0xFFB4006A),
    PaymentMethod.daviplata => const Color(0xFFC81E1E),
    PaymentMethod.bancolombiaQr => const Color(0xFF2B2B2B),
    PaymentMethod.breB => const Color(0xFF1D4ED8),
    PaymentMethod.otro => AppColors.outline,
    PaymentMethod.transferencia => AppColors.brandTeal,
  };

  Color get tint => switch (this) {
    PaymentMethod.efectivo => AppColors.emerald50,
    PaymentMethod.nequi => const Color(0xFFFDE7F3),
    PaymentMethod.daviplata => const Color(0xFFFDECEA),
    PaymentMethod.bancolombiaQr => const Color(0xFFFFF4C2),
    PaymentMethod.breB => const Color(0xFFE0E9FF),
    PaymentMethod.otro => AppColors.surfaceContainerHigh,
    PaymentMethod.transferencia => AppColors.brandTealLight,
  };

  String get subtitle => switch (this) {
    PaymentMethod.efectivo => 'En taquilla',
    PaymentMethod.nequi => 'Billetera digital',
    PaymentMethod.daviplata => 'App Daviplata',
    PaymentMethod.bancolombiaQr => 'Código QR',
    PaymentMethod.breB => 'Inmediata',
    PaymentMethod.transferencia => 'Cta. Ahorros',
    PaymentMethod.otro => 'Manual',
  };
}

extension PaymentConceptLabel on PaymentConcept {
  String get label => switch (this) {
    PaymentConcept.anticipo => 'Anticipo',
    PaymentConcept.saldo => 'Saldo',
    PaymentConcept.total => 'Pago total',
    PaymentConcept.venta => 'Venta',
  };
}

extension PaymentStatusLabel on PaymentStatus {
  String get tabLabel => switch (this) {
    PaymentStatus.pending => 'Por validar',
    PaymentStatus.approved => 'Aprobados',
    PaymentStatus.rejected => 'Rechazados',
    PaymentStatus.refunded => 'Devueltos',
  };

  /// Estado de un pago en singular (detalle de una reserva).
  String get label => switch (this) {
    PaymentStatus.pending => 'Por validar',
    PaymentStatus.approved => 'Aprobado',
    PaymentStatus.rejected => 'Rechazado',
    PaymentStatus.refunded => 'Devuelto',
  };
}

/// `Hoy · 7:00 p. m.`, `Mañana · 8:30 p. m.` o `9 oct · 7:00 p. m.`
String reservationWhen(DateTime start, DateTime now) {
  final day = DateTime(start.year, start.month, start.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = day.difference(today).inDays;
  final time = AppFormatters.time(start);
  return switch (diff) {
    0 => 'Hoy · $time',
    1 => 'Mañana · $time',
    -1 => 'Ayer · $time',
    _ => '${AppFormatters.shortDate(start)} · $time',
  };
}
