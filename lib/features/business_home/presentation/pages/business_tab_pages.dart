import 'package:flutter/material.dart';

import '../widgets/business_tab_placeholder.dart';

// TODO: reemplazar cada sección por su diseño (en Stitch ya existe
// "Crear Cancha").

class BusinessDashboardPage extends StatelessWidget {
  const BusinessDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => const BusinessTabPlaceholder(
    title: 'Dashboard',
    subtitle: 'Rendimiento de tu negocio',
    icon: Icons.insights,
    message: 'Aquí verás ingresos, ocupación y cierre de caja.',
  );
}
