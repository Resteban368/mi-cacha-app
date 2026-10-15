import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/widgets/loading_dialog.dart';

/// Cubit mínimo: `true` = cargando.
class _LoadingCubit extends Cubit<bool> {
  _LoadingCubit(super.initialState);

  void set(bool loading) => emit(loading);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_LoadingCubit> pump(
    WidgetTester tester, {
    required bool loading,
  }) async {
    final cubit = _LoadingCubit(loading);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: BlocLoadingDialog<_LoadingCubit, bool>(
              isLoading: (loading) => loading,
              child: const Text('contenido'),
            ),
          ),
        ),
      ),
    );
    return cubit;
  }

  Finder dialog() => find.byType(AppLoadingDialog);

  testWidgets('al cargar muestra el diálogo con el ícono y el mensaje', (
    tester,
  ) async {
    await pump(tester, loading: true);
    // Aún no: solo aparece si la carga tarda más de 150 ms.
    expect(dialog(), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 300));
    expect(dialog(), findsOneWidget);
    expect(find.text('Cargando información'), findsOneWidget);
    expect(find.text('Espere un momento…'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('se cierra al terminar la carga', (tester) async {
    final cubit = await pump(tester, loading: true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(dialog(), findsOneWidget);

    cubit.set(false);
    await tester.pumpAndSettle();
    expect(dialog(), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('una carga rápida no llega a mostrarlo', (tester) async {
    final cubit = await pump(tester, loading: true);
    await tester.pump(const Duration(milliseconds: 50));
    cubit.set(false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(dialog(), findsNothing);
  });

  testWidgets('no se apila ni se cierra con atrás', (tester) async {
    final cubit = await pump(tester, loading: false);
    cubit.set(true);
    await tester.pump(const Duration(milliseconds: 500));
    cubit
      ..set(false)
      ..set(true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(dialog(), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(dialog(), findsOneWidget);
  });
}
