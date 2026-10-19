/// Permiso de notificaciones del navegador.
enum PushPermission {
  defaultState,
  granted,
  denied;

  static PushPermission fromBrowser(String value) => switch (value) {
    'granted' => PushPermission.granted,
    'denied' => PushPermission.denied,
    _ => PushPermission.defaultState,
  };
}
