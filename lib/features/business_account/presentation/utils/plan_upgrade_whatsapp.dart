import 'package:flutter/material.dart';

import '../../../../core/utils/contact_launcher.dart';

/// WhatsApp de ventas de Mi Cancha: ahí se pide el cambio de plan.
const planSalesWhatsApp = '+573208806654';

/// Chat con ventas con el pedido ya escrito.
Uri planUpgradeWhatsAppUri(String nextPlan, {String? businessName}) {
  final name = businessName?.trim();
  final text = name == null || name.isEmpty
      ? 'Hola, quiero cambiar mi negocio al plan $nextPlan.'
      : 'Hola, soy el administrador de $name y quiero cambiar al plan '
            '$nextPlan.';
  return ContactLauncher.whatsAppChat(planSalesWhatsApp, text: text)!;
}

/// Chat con ventas pidiendo activar el módulo de Ventas e inventario.
Uri salesModuleRequestWhatsAppUri({String? businessName}) {
  final name = businessName?.trim();
  final text = name == null || name.isEmpty
      ? 'Hola, quiero activar el módulo de Ventas e inventario para mi '
            'negocio.'
      : 'Hola, soy el administrador de $name y quiero activar el módulo de '
            'Ventas e inventario.';
  return ContactLauncher.whatsAppChat(planSalesWhatsApp, text: text)!;
}

/// Abre el chat de cambio de plan; si no se puede, lo avisa.
Future<void> openPlanUpgrade(
  BuildContext context,
  String nextPlan, {
  String? businessName,
  UrlOpener? opener,
}) => _openSalesChat(
  context,
  planUpgradeWhatsAppUri(nextPlan, businessName: businessName),
  opener,
);

/// Abre el chat para pedir el módulo de Ventas e inventario.
Future<void> openSalesModuleRequest(
  BuildContext context, {
  String? businessName,
  UrlOpener? opener,
}) => _openSalesChat(
  context,
  salesModuleRequestWhatsAppUri(businessName: businessName),
  opener,
);

/// Abre el chat con ventas; si no se puede, deja el número a la vista.
Future<void> _openSalesChat(
  BuildContext context,
  Uri uri,
  UrlOpener? opener,
) async {
  final opened = opener == null
      ? await ContactLauncher.open(uri)
      : await ContactLauncher.open(uri, opener: opener);
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'No pudimos abrir WhatsApp. Escríbenos al +57 320 880 6654.',
        ),
      ),
    );
}
