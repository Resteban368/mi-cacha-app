import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/media/image_upload.dart';
import 'package:mi_cancha/features/business_coupons/data/datasources/coupons_api_data_source.dart';
import 'package:mi_cancha/features/business_coupons/domain/entities/coupon.dart';
import 'package:mi_cancha/features/business_coupons/domain/repositories/coupon_repository.dart';
import 'package:mi_cancha/features/business_coupons/domain/usecases/coupon_usecases.dart';
import 'package:mi_cancha/features/business_coupons/presentation/bloc/coupon_detail_cubit.dart';
import 'package:mi_cancha/features/business_coupons/presentation/bloc/coupons_cubit.dart';
import 'package:mi_cancha/features/business_coupons/presentation/widgets/coupon_labels.dart';
import 'package:mi_cancha/features/business_coupons/presentation/widgets/redeem_coupon_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/api_dio.dart';
import '../../helpers/fake_http_adapter.dart';

class _MockRepository extends Mock implements CouponRepository {}

Object? _body(Object? data) => data is String ? jsonDecode(data) : data;

const _coupon = Coupon(
  id: 'c-1',
  name: 'Frecuente',
  requiredReservations: 10,
  rewardType: CouponRewardType.freeCourt,
  rewardDescription: 'Una hora gratis',
  redeemedCount: 3,
  state: CouponState.active,
  isActive: true,
  maxRedemptions: 50,
);

CouponCard _card(String id) => CouponCard(
  id: id,
  customerName: 'Ana',
  customerPhone: '300',
  status: CouponCardStatus.redeemed,
  completed: 10,
  required: 10,
  stamps: const [],
);

void main() {
  group('SaveCoupon', () {
    final repository = _MockRepository();
    final save = SaveCoupon(repository);
    CouponDraft draft({String name = 'Frecuente', int? percent, int? max}) => (
      id: null,
      name: name,
      requiredReservations: 10,
      rewardType: percent == null
          ? CouponRewardType.freeCourt
          : CouponRewardType.percent,
      percent: percent,
      rewardDescription: 'Premio',
      expiresOn: null,
      maxRedemptions: max,
    );

    setUpAll(() => registerFallbackValue(draft()));

    test('rechaza datos inválidos antes de llamar a la API', () {
      expect(() => save(draft(name: ' ')), throwsArgumentError);
      expect(() => save(draft(percent: 0)), throwsArgumentError);
      expect(() => save(draft(max: 0)), throwsArgumentError);
      verifyNever(() => repository.save(any()));
    });
  });

  group('CouponsApiDataSource', () {
    test('crea con fecha sin hora; sin límite envía null', () async {
      Object? sent;
      final adapter = FakeHttpAdapter((options) {
        sent = _body(options.data);
        return (
          201,
          {
            'id': 'c-1',
            'name': 'Frecuente',
            'requiredReservations': 10,
            'rewardType': 'FREE_COURT',
            'rewardDescription': 'Una hora gratis',
            'redeemedCount': 0,
            'state': 'ACTIVE',
            'isActive': true,
          },
        );
      });
      final source = CouponsApiDataSource(apiDio(adapter));
      final saved = await source.save((
        id: null,
        name: ' Frecuente ',
        requiredReservations: 10,
        rewardType: CouponRewardType.freeCourt,
        percent: null,
        rewardDescription: 'Una hora gratis',
        expiresOn: DateTime(2026, 12, 31),
        maxRedemptions: null,
      ));
      expect(sent, {
        'name': 'Frecuente',
        'rewardDescription': 'Una hora gratis',
        'expiresOn': '2026-12-31',
        'maxRedemptions': null,
        'requiredReservations': 10,
        'rewardType': 'FREE_COURT',
      });
      expect(saved.state, CouponState.active);
    });
  });

  group('imagen del cupón', () {
    final jpg = ImageUpload(
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]),
      fileName: 'a.jpg',
    );
    const draft = (
      id: null,
      name: 'Frecuente',
      requiredReservations: 10,
      rewardType: CouponRewardType.freeCourt,
      percent: null,
      rewardDescription: 'Premio',
      expiresOn: null,
      maxRedemptions: null,
    );
    late _MockRepository repository;
    late CouponsCubit cubit;

    setUpAll(() {
      registerFallbackValue(jpg);
      registerFallbackValue(draft as CouponDraft);
    });

    setUp(() {
      repository = _MockRepository();
      when(() => repository.save(any())).thenAnswer((_) async => _coupon);
      cubit = CouponsCubit(
        getCoupons: GetCoupons(repository),
        saveCoupon: SaveCoupon(repository),
        setCouponActive: SetCouponActive(repository),
        setCouponImage: SetCouponImage(repository),
        removeCouponImage: RemoveCouponImage(repository),
      );
    });

    tearDown(() => cubit.close());

    test('sin imagen no llama a subirla', () async {
      final result = await cubit.save(draft);
      expect(result.error, isNull);
      expect(result.warning, isNull);
      verifyNever(() => repository.setImage(any(), any()));
    });

    test('con imagen la sube al cupón recién guardado', () async {
      when(
        () => repository.setImage('c-1', any()),
      ).thenAnswer((_) async => _coupon);
      final result = await cubit.save(draft, image: jpg);
      expect(result.warning, isNull);
      verify(() => repository.setImage('c-1', jpg)).called(1);
    });

    test('si falla la imagen, el cupón queda y solo avisa', () async {
      when(() => repository.setImage(any(), any())).thenThrow(Exception('red'));
      final result = await cubit.save(draft, image: jpg);
      expect(result.error, isNull);
      expect(result.warning, contains('El cupón se guardó'));
      expect(cubit.state.coupons, [_coupon]);
    });

    test('una imagen inválida no llega a la API', () async {
      final result = await cubit.save(
        draft,
        image: ImageUpload(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'a.gif',
        ),
      );
      expect(result.warning, contains('JPG o PNG'));
      verifyNever(() => repository.setImage(any(), any()));
    });

    test('quitar la imagen llama a la API', () async {
      when(
        () => repository.removeImage('c-1'),
      ).thenAnswer((_) async => _coupon);
      await cubit.save(draft, removeImage: true);
      verify(() => repository.removeImage('c-1')).called(1);
    });
  });

  group('etiquetas', () {
    test('muestran el límite o ilimitado', () {
      expect(couponRedemptionsLabel(_coupon), '3 de 50 redimidos');
      expect(
        couponRedemptionsLabel(
          const Coupon(
            id: 'c',
            name: 'x',
            requiredReservations: 1,
            rewardType: CouponRewardType.percent,
            percent: 20,
            rewardDescription: 'x',
            redeemedCount: 2,
            state: CouponState.active,
            isActive: true,
          ),
        ),
        '2 redimidos · ilimitado',
      );
    });
  });

  group('CouponDetailCubit', () {
    late _MockRepository repository;
    late CouponDetailCubit cubit;

    setUpAll(() {
      registerFallbackValue(CouponCardStatus.redeemed);
    });

    setUp(() {
      repository = _MockRepository();
      when(() => repository.coupon('c-1')).thenAnswer((_) async => _coupon);
      cubit = CouponDetailCubit(
        getCoupon: GetCoupon(repository),
        getCards: GetCouponCards(repository),
      );
    });

    tearDown(() => cubit.close());

    test('carga los redimidos y pagina', () async {
      when(
        () =>
            repository.cards('c-1', status: CouponCardStatus.redeemed, page: 1),
      ).thenAnswer((_) async => (items: [_card('a')], total: 2));
      when(
        () =>
            repository.cards('c-1', status: CouponCardStatus.redeemed, page: 2),
      ).thenAnswer((_) async => (items: [_card('b')], total: 2));

      await cubit.load('c-1');
      expect(cubit.state.cards.map((c) => c.id), ['a']);
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.cards.map((c) => c.id), ['a', 'b']);
      expect(cubit.state.hasMore, isFalse);
    });

    test('un fallo de las tarjetas no pierde el cupón', () async {
      when(
        () => repository.cards(
          any(),
          status: any(named: 'status'),
          page: any(named: 'page'),
        ),
      ).thenThrow(Exception('red'));
      await cubit.load('c-1');
      expect(cubit.state.load, CouponDetailLoad.ready);
      expect(cubit.state.cardsFailed, isTrue);
    });
  });

  group('showRedeemCouponDialog', () {
    testWidgets('sin bonos lo avisa y no ofrece redimir', (tester) async {
      final repository = _MockRepository();
      when(
        () => repository.forCustomer('cu-1'),
      ).thenAnswer((_) async => const []);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRedeemCouponDialog(
                context,
                reservationId: 'r-1',
                customerId: 'cu-1',
                courts: 1,
                getCoupons: GetCustomerCoupons(repository),
                redeem: RedeemCoupon(repository),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(
        find.text('Este cliente no tiene bonos para redimir.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('redeem-confirm')), findsNothing);
    });

    testWidgets('redime eligiendo cuántas canchas regala', (tester) async {
      final repository = _MockRepository();
      when(() => repository.forCustomer('cu-1')).thenAnswer(
        (_) async => const [
          CustomerCoupon(
            coupon: _coupon,
            cardId: 'card-1',
            status: CouponCardStatus.earned,
            completed: 10,
            required: 10,
            stamps: [],
          ),
        ],
      );
      when(
        () => repository.redeem(
          reservationId: 'r-1',
          cardId: 'card-1',
          courts: 2,
        ),
      ).thenAnswer((_) async => (amount: 160000, courts: 2, balance: 0));
      CouponRedemption? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showRedeemCouponDialog(
                  context,
                  reservationId: 'r-1',
                  customerId: 'cu-1',
                  courts: 2,
                  getCoupons: GetCustomerCoupons(repository),
                  redeem: RedeemCoupon(repository),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('redeem-courts')), findsOneWidget);
      await tester.tap(find.byKey(const Key('redeem-confirm')));
      await tester.pumpAndSettle();
      expect(result?.amount, 160000);
    });
  });
}
