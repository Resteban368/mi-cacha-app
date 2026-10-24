import '../../../../core/usecase/usecase.dart';
import '../entities/online_booking_link.dart';
import '../repositories/business_repository.dart';

class GetOnlineBookingLink implements UseCase<OnlineBookingLink, NoParams> {
  const GetOnlineBookingLink(this._repository);

  final BusinessRepository _repository;

  @override
  Future<OnlineBookingLink> call(NoParams params) =>
      _repository.getOnlineBookingLink();
}
