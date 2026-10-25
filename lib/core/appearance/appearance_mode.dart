/// Modo de apariencia que elige el usuario.
enum AppearanceMode {
  /// Sigue el modo claro/oscuro del sistema.
  system('system', 'Sistema'),
  light('light', 'Claro'),
  dark('dark', 'Oscuro');

  const AppearanceMode(this.storageCode, this.label);

  final String storageCode;
  final String label;

  static AppearanceMode fromStorage(String? code) => values.firstWhere(
    (mode) => mode.storageCode == code,
    orElse: () => AppearanceMode.system,
  );
}
