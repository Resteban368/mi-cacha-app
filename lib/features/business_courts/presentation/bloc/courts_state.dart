part of 'courts_bloc.dart';

enum CourtsStatus { loading, ready, failure }

final class CourtsState extends Equatable {
  const CourtsState({
    this.status = CourtsStatus.loading,
    this.courts = const [],
  });

  final CourtsStatus status;
  final List<Court> courts;

  CourtsState copyWith({CourtsStatus? status, List<Court>? courts}) =>
      CourtsState(status: status ?? this.status, courts: courts ?? this.courts);

  @override
  List<Object?> get props => [status, courts];
}
