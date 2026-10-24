import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/business_account/domain/entities/password_change.dart';
import 'package:mi_cancha/features/business_account/domain/usecases/change_password.dart';
import 'package:mi_cancha/features/business_account/presentation/bloc/change_password_cubit.dart';
import 'package:mi_cancha/features/business_account/presentation/widgets/change_password_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _MockChangePassword extends Mock implements ChangePassword {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(
      const PasswordChange(currentPassword: 'a', newPassword: 'b'),
    );
  });

  late _MockChangePassword changePassword;
  setUp(() => changePassword = _MockChangePassword());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showChangePasswordDialog(
                context,
                createCubit: () =>
                    ChangePasswordCubit(changePassword: changePassword),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String current = 'actual123',
    String next = 'nueva12345',
    String? confirm,
  }) async {
    Finder field(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(field('password-current'), current);
    await tester.enterText(field('password-new'), next);
    await tester.enterText(field('password-confirm'), confirm ?? next);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('password-submit')));
    await tester.pump();
  }

  testWidgets('3 campos con mostrar/ocultar', (tester) async {
    await open(tester);

    // AppTextField muestra la etiqueta en mayúsculas.
    expect(find.text('CONTRASEÑA ACTUAL'), findsOneWidget);
    expect(find.text('NUEVA CONTRASEÑA'), findsOneWidget);
    expect(find.text('CONFIRMAR NUEVA CONTRASEÑA'), findsOneWidget);
    expect(find.byTooltip('Mostrar contraseña'), findsNWidgets(3));
  });

  testWidgets('valida largo y que coincidan antes de enviar', (tester) async {
    await open(tester);

    await fill(tester, next: 'corta', confirm: 'corta');
    await submit(tester);
    expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);

    await fill(tester, next: 'a' * 73, confirm: 'a' * 73);
    await submit(tester);
    expect(find.text('Debe tener máximo 72 caracteres'), findsOneWidget);

    await fill(tester, confirm: 'otra12345');
    await submit(tester);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    verifyNever(() => changePassword(any()));
  });

  testWidgets('la nueva no puede ser igual a la actual', (tester) async {
    await open(tester);
    await fill(tester, current: 'misma1234', next: 'misma1234');
    await submit(tester);

    expect(find.text('Debe ser distinta a la actual'), findsOneWidget);
    verifyNever(() => changePassword(any()));
  });

  testWidgets('error 400: muestra el mensaje de la API y sigue abierto', (
    tester,
  ) async {
    when(() => changePassword(any())).thenThrow(
      const PasswordChangeException(
        PasswordChangeFailure.rejected,
        message: 'La contraseña actual no es correcta',
      ),
    );
    await open(tester);
    await fill(tester);
    await submit(tester);
    await tester.pump();

    expect(find.byKey(const Key('password-error')), findsOneWidget);
    expect(find.text('La contraseña actual no es correcta'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
  });

  testWidgets('envía, deshabilita el botón y al terminar cierra y avisa', (
    tester,
  ) async {
    final response = Completer<void>();
    when(() => changePassword(any())).thenAnswer((_) => response.future);
    await open(tester);
    await fill(tester);
    await submit(tester);

    verify(
      () => changePassword(
        const PasswordChange(
          currentPassword: 'actual123',
          newPassword: 'nueva12345',
        ),
      ),
    ).called(1);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('password-submit')))
          .onPressed,
      isNull,
    );

    response.complete();
    await tester.pumpAndSettle();
    expect(find.text('Cambiar contraseña'), findsNothing);
    expect(find.text('Contraseña actualizada'), findsOneWidget);
  });

  testWidgets('cancelar cierra sin enviar', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('password-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar contraseña'), findsNothing);
    verifyNever(() => changePassword(any()));
  });
}
