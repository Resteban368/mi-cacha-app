import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_payments/presentation/bloc/new_payment/new_payment_bloc.dart';
import 'package:mi_cancha/features/business_payments/presentation/widgets/new_payment_shimmer.dart';
import 'package:mi_cancha/features/business_payments/presentation/widgets/new_payment_target_selector.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/customer.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';

void main() {
  const sampleCustomer = Customer(
    id: 'cust-1',
    name: 'Carlos Ruiz',
    phone: '3001234567',
    documentId: '10102020',
  );

  final sampleReservation = Reservation(
    id: 'res-1',
    courtName: 'Cancha Sintética 1',
    sport: Sport.futbol,
    start: DateTime(2026, 10, 15, 18),
    end: DateTime(2026, 10, 15, 19),
    customerName: 'Carlos Ruiz',
    phone: '3001234567',
    totalPrice: 80000,
    amountPaid: 30000,
    status: ReservationStatus.confirmed,
    customer: sampleCustomer,
  );

  Widget createWidget({
    NewPaymentState state = const NewPaymentState(),
    TextEditingController? manualController,
    ValueChanged<PaymentTargetMode>? onModeChanged,
    ValueChanged<String>? onCustomerSearchChanged,
    ValueChanged<Customer?>? onCustomerSelected,
    ValueChanged<String>? onReservationSearchChanged,
    ValueChanged<Reservation?>? onReservationSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: NewPaymentTargetSelector(
            state: state,
            manualCustomerController:
                manualController ?? TextEditingController(),
            onModeChanged: onModeChanged ?? (_) {},
            onCustomerSearchChanged: onCustomerSearchChanged ?? (_) {},
            onCustomerSelected: onCustomerSelected ?? (_) {},
            onReservationSearchChanged: onReservationSearchChanged ?? (_) {},
            onReservationSelected: onReservationSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('NewPaymentTargetSelector', () {
    testWidgets('renders tabs correctly', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Por Cliente'), findsOneWidget);
      expect(find.text('Por Reserva'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
    });

    testWidgets('switches to reservation mode on tab tap', (tester) async {
      PaymentTargetMode? selectedMode;
      await tester.pumpWidget(
        createWidget(onModeChanged: (mode) => selectedMode = mode),
      );

      await tester.tap(find.text('Por Reserva'));
      await tester.pump();

      expect(selectedMode, PaymentTargetMode.reservation);
    });

    testWidgets('shows customer results and triggers selection', (
      tester,
    ) async {
      Customer? picked;
      await tester.pumpWidget(
        createWidget(
          state: const NewPaymentState(
            customerResults: [sampleCustomer],
            customerSearchStatus: EntitySearchStatus.ready,
          ),
          onCustomerSelected: (c) => picked = c,
        ),
      );

      expect(find.text('Carlos Ruiz'), findsOneWidget);
      expect(find.text('3001234567 · CC 10102020'), findsOneWidget);

      await tester.tap(find.text('Carlos Ruiz'));
      await tester.pump();

      expect(picked, sampleCustomer);
    });

    testWidgets('shows selected customer card and reservations', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          state: NewPaymentState(
            selectedCustomer: sampleCustomer,
            customerReservations: [sampleReservation],
            customerReservationsStatus: EntitySearchStatus.ready,
          ),
        ),
      );

      expect(find.text('Carlos Ruiz'), findsOneWidget);
      expect(find.text('RESERVAS DE CARLOS RUIZ'), findsOneWidget);
      expect(find.text('Cancha Sintética 1'), findsOneWidget);
      expect(find.text(r'Pendiente: $50.000'), findsOneWidget);
    });

    testWidgets('shows shimmer when loading customers', (tester) async {
      await tester.pumpWidget(
        createWidget(
          state: const NewPaymentState(
            customerSearchStatus: EntitySearchStatus.loading,
          ),
        ),
      );

      expect(find.byType(NewPaymentCustomerListShimmer), findsOneWidget);
    });
  });
}
