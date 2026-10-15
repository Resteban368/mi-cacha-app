part of 'splash_bloc.dart';

final class SplashState extends Equatable {
  const SplashState({this.version = '', this.destination});

  final String version;

  /// `null` mientras se resuelve; al tener valor la vista navega.
  final StartDestination? destination;

  SplashState copyWith({String? version, StartDestination? destination}) =>
      SplashState(
        version: version ?? this.version,
        destination: destination ?? this.destination,
      );

  @override
  List<Object?> get props => [version, destination];
}
