import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/utils/formatters.dart';

void main() {
  test('cop usa punto de miles y sin decimales', () {
    expect(AppFormatters.cop(0), r'$0');
    expect(AppFormatters.cop(900), r'$900');
    expect(AppFormatters.cop(90000), r'$90.000');
    expect(AppFormatters.cop(1250000), r'$1.250.000');
  });

  test('copCompact abrevia miles y millones', () {
    expect(AppFormatters.copCompact(640000), r'$640K');
    expect(AppFormatters.copCompact(2000000), r'$2M');
    expect(AppFormatters.copCompact(1250000), r'$1,3M');
    expect(AppFormatters.copCompact(500), r'$500');
  });

  test('time usa 12 h con a. m. / p. m.', () {
    expect(AppFormatters.time(DateTime(2026, 1, 1, 19, 15)), '7:15 p. m.');
    expect(AppFormatters.time(DateTime(2026, 1, 1, 0, 5)), '12:05 a. m.');
    expect(AppFormatters.time(DateTime(2026, 1, 1, 12)), '12:00 p. m.');
  });

  test('timeRange repite el meridiano solo si cambia', () {
    expect(
      AppFormatters.timeRange(
        DateTime(2026, 1, 1, 16, 30),
        DateTime(2026, 1, 1, 18),
      ),
      '4:30 – 6:00 p. m.',
    );
    expect(
      AppFormatters.timeRange(
        DateTime(2026, 1, 1, 11, 30),
        DateTime(2026, 1, 1, 13),
      ),
      '11:30 a. m. – 1:00 p. m.',
    );
  });

  test('duration', () {
    expect(AppFormatters.duration(const Duration(minutes: 90)), '1h 30m');
    expect(AppFormatters.duration(const Duration(hours: 1)), '1h');
    expect(AppFormatters.duration(const Duration(minutes: 45)), '45m');
  });

  test('longDate en español', () {
    expect(
      AppFormatters.longDate(DateTime(2026, 10, 9)),
      'Viernes, 9 de octubre de 2026',
    );
  });
}
