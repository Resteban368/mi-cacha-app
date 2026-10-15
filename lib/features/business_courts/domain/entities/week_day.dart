/// Días de la semana tal como los maneja la API (`MONDAY` … `SUNDAY`).
enum WeekDay {
  monday('MONDAY', 'Lunes', 'Lun'),
  tuesday('TUESDAY', 'Martes', 'Mar'),
  wednesday('WEDNESDAY', 'Miércoles', 'Mié'),
  thursday('THURSDAY', 'Jueves', 'Jue'),
  friday('FRIDAY', 'Viernes', 'Vie'),
  saturday('SATURDAY', 'Sábado', 'Sáb'),
  sunday('SUNDAY', 'Domingo', 'Dom');

  const WeekDay(this.apiCode, this.label, this.shortLabel);

  final String apiCode;
  final String label;
  final String shortLabel;

  static WeekDay? fromApi(String code) {
    for (final day in values) {
      if (day.apiCode == code) return day;
    }
    return null;
  }
}
