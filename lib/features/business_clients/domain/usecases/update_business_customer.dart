import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/client_profile.dart';
import '../entities/customer_payload.dart';
import '../repositories/business_customers_repository.dart';

class UpdateCustomerParams extends Equatable {
  const UpdateCustomerParams({required this.id, required this.payload});

  final String id;
  final CustomerPayload payload;

  @override
  List<Object?> get props => [id, payload];
}

class UpdateBusinessCustomer
    implements UseCase<ClientProfile, UpdateCustomerParams> {
  const UpdateBusinessCustomer(this._repository);

  final BusinessCustomersRepository _repository;

  @override
  Future<ClientProfile> call(UpdateCustomerParams params) {
    return _repository.updateCustomer(params.id, params.payload);
  }
}
