part of 'business_account_bloc.dart';

enum BusinessAccountStatus { initial, loading, ready, failure }

final class BusinessAccountState extends Equatable {
  const BusinessAccountState({
    this.status = BusinessAccountStatus.initial,
    this.account,
    this.venue,
    this.version,
  });

  final BusinessAccountStatus status;
  final BusinessAccount? account;

  /// Sede registrada en "Mi negocio"; `null` si aún no se creó.
  final Business? venue;

  /// Versión de la app para el pie; `null` si no se pudo leer.
  final String? version;

  BusinessAccountState copyWith({BusinessAccountStatus? status}) =>
      BusinessAccountState(
        status: status ?? this.status,
        account: account,
        venue: venue,
        version: version,
      );

  @override
  List<Object?> get props => [status, account, venue, version];
}
