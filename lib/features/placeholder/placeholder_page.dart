import 'package:flutter/material.dart';

/// Pantalla temporal para rutas cuyo diseño aún no se implementa.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — próximamente')),
    );
  }
}
