import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/online_booking_link.dart';
import 'package:mi_cancha/features/business_profile/presentation/bloc/business_profile_bloc.dart';
import 'package:mi_cancha/features/business_profile/presentation/widgets/online_booking_card.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const live = OnlineBookingLink(
    url: 'https://mi-cancha-api.vercel.app/reservar/el-campin',
    slug: 'el-campin',
    enabled: true,
    bookingAvailable: true,
  );

  late List<Uri> opened;
  var openResult = true;
  var retries = 0;

  setUp(() {
    opened = [];
    openResult = true;
    retries = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    OnlineBookingStatus status = OnlineBookingStatus.ready,
    OnlineBookingLink? link = live,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: OnlineBookingCard(
              status: status,
              link: link,
              businessName: 'El Campín',
              onRetry: () => retries++,
              opener: (uri) async {
                opened.add(uri);
                return openResult;
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra el link activo con sus acciones', (tester) async {
    await pump(tester);

    expect(find.text('Link de reservas en línea'), findsOneWidget);
    expect(find.text(live.url), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);
    expect(find.byKey(const Key('online-booking-warning')), findsNothing);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('copiar deja el link en el portapapeles', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester);

    await tester.tap(find.byKey(const Key('online-booking-copy')));
    await tester.pump();
    expect(copied, live.url);
    expect(find.text('Link copiado'), findsOneWidget);
  });

  testWidgets('WhatsApp comparte el link con el nombre de la sede', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('online-booking-whatsapp')));
    await tester.pump();

    final uri = opened.single;
    expect(uri.host, 'wa.me');
    expect(
      uri.queryParameters['text'],
      'Reserva tu cancha en El Campín aquí: ${live.url}',
    );
  });

  testWidgets('abrir usa el link; si no se puede, avisa', (tester) async {
    openResult = false;
    await pump(tester);
    await tester.tap(find.byKey(const Key('online-booking-open')));
    await tester.pump();

    expect(opened.single, Uri.parse(live.url));
    expect(find.text('No pudimos abrir el enlace.'), findsOneWidget);
  });

  testWidgets('sin reservas muestra el motivo de la API', (tester) async {
    await pump(
      tester,
      link: const OnlineBookingLink(
        url: 'https://x/reservar/el-campin',
        slug: 'el-campin',
        enabled: true,
        bookingAvailable: false,
        unavailableReason: 'Aún no tienes canchas listas para reservar',
      ),
    );

    expect(find.text('Sin reservas'), findsOneWidget);
    expect(
      find.text('Aún no tienes canchas listas para reservar'),
      findsOneWidget,
    );
  });

  testWidgets('link desactivado', (tester) async {
    await pump(
      tester,
      link: const OnlineBookingLink(
        url: 'https://x/reservar/el-campin',
        slug: 'el-campin',
        enabled: false,
        bookingAvailable: false,
      ),
    );

    expect(find.text('Desactivado'), findsOneWidget);
    expect(find.byKey(const Key('online-booking-warning')), findsOneWidget);
  });

  testWidgets('cargando muestra un shimmer', (tester) async {
    await pump(tester, status: OnlineBookingStatus.loading, link: null);
    expect(find.byKey(const Key('online-booking-loading')), findsOneWidget);
  });

  testWidgets('error con reintento', (tester) async {
    await pump(tester, status: OnlineBookingStatus.failure, link: null);
    expect(find.text('No pudimos cargar tu link de reservas.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('online-booking-retry')));
    expect(retries, 1);
  });

  testWidgets('sin overflow en 320 de ancho', (tester) async {
    await pump(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}
