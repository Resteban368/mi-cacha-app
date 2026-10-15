part of 'business_account_bloc.dart';

sealed class BusinessAccountEvent extends Equatable {
  const BusinessAccountEvent();

  @override
  List<Object?> get props => [];
}

/// Carga (o recarga) los datos de la cuenta.
final class BusinessAccountRequested extends BusinessAccountEvent {
  const BusinessAccountRequested();
}
