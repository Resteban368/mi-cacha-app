import 'package:equatable/equatable.dart';

import '../../../business_profile/domain/entities/business.dart';

/// Paso pendiente de la configuración inicial del panel, en orden.
enum SetupStep {
  /// Faltan datos del negocio.
  business,

  /// El negocio está completo pero no hay una cancha lista para reservas.
  court,

  /// Todo listo: el panel se usa sin restricciones.
  done,
}

/// En qué paso va el negocio y, en el primero, qué le falta.
class SetupProgress extends Equatable {
  const SetupProgress(this.step, {this.missing = const []});

  static const done = SetupProgress(SetupStep.done);

  final SetupStep step;

  /// Datos del negocio que faltan (solo en [SetupStep.business]).
  final List<BusinessRequirement> missing;

  @override
  List<Object?> get props => [step, missing];
}
