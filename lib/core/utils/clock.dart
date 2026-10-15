/// Fuente de la hora actual, inyectable para poder testear lógica temporal.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}
