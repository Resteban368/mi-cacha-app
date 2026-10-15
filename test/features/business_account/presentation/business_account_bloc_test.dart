import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_account/domain/usecases/get_business_account.dart';
import 'package:mi_cancha/features/business_account/presentation/bloc/business_account_bloc.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/get_my_business.dart';
import 'package:mi_cancha/features/splash/domain/usecases/get_app_version.dart';
import 'package:mocktail/mocktail.dart';

import '../../business_profile/business_fixtures.dart';
import '../account_fixtures.dart';

class _MockGetAccount extends Mock implements GetBusinessAccount {}

class _MockGetMyBusiness extends Mock implements GetMyBusiness {}

class _MockGetAppVersion extends Mock implements GetAppVersion {}

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  late _MockGetAccount getAccount;
  late _MockGetMyBusiness getMyBusiness;
  late _MockGetAppVersion getAppVersion;

  setUp(() {
    getAccount = _MockGetAccount();
    getMyBusiness = _MockGetMyBusiness();
    getAppVersion = _MockGetAppVersion();
    when(() => getAccount(any())).thenAnswer((_) async => account);
    when(() => getMyBusiness(any())).thenAnswer((_) async => business);
    when(() => getAppVersion(any())).thenAnswer((_) async => '1.0.0');
  });

  BusinessAccountBloc build() => BusinessAccountBloc(
    getAccount: getAccount,
    getMyBusiness: getMyBusiness,
    getAppVersion: getAppVersion,
  );

  blocTest<BusinessAccountBloc, BusinessAccountState>(
    'combina cuenta, sede y versión',
    build: build,
    act: (bloc) => bloc.add(const BusinessAccountRequested()),
    expect: () => [
      const BusinessAccountState(status: BusinessAccountStatus.loading),
      BusinessAccountState(
        status: BusinessAccountStatus.ready,
        account: account,
        venue: business,
        version: '1.0.0',
      ),
    ],
  );

  blocTest<BusinessAccountBloc, BusinessAccountState>(
    'sin sede registrada queda lista con venue nulo',
    setUp: () => when(() => getMyBusiness(any())).thenAnswer((_) async => null),
    build: build,
    act: (bloc) => bloc.add(const BusinessAccountRequested()),
    skip: 1,
    expect: () => [
      BusinessAccountState(
        status: BusinessAccountStatus.ready,
        account: account,
        version: '1.0.0',
      ),
    ],
  );

  blocTest<BusinessAccountBloc, BusinessAccountState>(
    'si falla la versión la pantalla carga igual',
    setUp: () =>
        when(() => getAppVersion(any())).thenThrow(Exception('plugin')),
    build: build,
    act: (bloc) => bloc.add(const BusinessAccountRequested()),
    skip: 1,
    expect: () => [
      BusinessAccountState(
        status: BusinessAccountStatus.ready,
        account: account,
        venue: business,
      ),
    ],
  );

  blocTest<BusinessAccountBloc, BusinessAccountState>(
    'si falla la cuenta emite failure',
    setUp: () => when(() => getAccount(any())).thenThrow(Exception('red')),
    build: build,
    act: (bloc) => bloc.add(const BusinessAccountRequested()),
    expect: () => [
      const BusinessAccountState(status: BusinessAccountStatus.loading),
      const BusinessAccountState(status: BusinessAccountStatus.failure),
    ],
  );
}
