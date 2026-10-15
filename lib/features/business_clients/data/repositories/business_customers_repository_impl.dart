import '../../../../core/network/api_exception.dart';
import '../../domain/entities/client_profile.dart';
import '../../domain/entities/customer_failure.dart';
import '../../domain/entities/customer_payload.dart';
import '../../domain/entities/customer_query.dart';
import '../../domain/entities/customers_page_result.dart';
import '../../domain/repositories/business_customers_repository.dart';
import '../datasources/business_customers_data_source.dart';

class BusinessCustomersRepositoryImpl implements BusinessCustomersRepository {
  const BusinessCustomersRepositoryImpl(this._dataSource);

  final BusinessCustomersDataSource _dataSource;

  @override
  Future<CustomersPageResult> getCustomers(CustomerQuery query) async {
    try {
      return await _dataSource.getCustomers(query);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } catch (e) {
      throw CustomerException(
        failure: CustomerFailure.server,
        message: e.toString(),
      );
    }
  }

  @override
  Future<ClientProfile> createCustomer(CustomerPayload payload) async {
    try {
      return await _dataSource.createCustomer(payload);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } catch (e) {
      throw CustomerException(
        failure: CustomerFailure.server,
        message: e.toString(),
      );
    }
  }

  @override
  Future<ClientProfile> updateCustomer(
    String id,
    CustomerPayload payload,
  ) async {
    try {
      return await _dataSource.updateCustomer(id, payload);
    } on ApiException catch (e) {
      throw _mapApiException(e);
    } catch (e) {
      throw CustomerException(
        failure: CustomerFailure.server,
        message: e.toString(),
      );
    }
  }

  CustomerException _mapApiException(ApiException e) {
    final failure = switch (e.kind) {
      ApiErrorKind.conflict => CustomerFailure.conflict,
      ApiErrorKind.badRequest => CustomerFailure.invalid,
      ApiErrorKind.notFound => CustomerFailure.notFound,
      ApiErrorKind.network => CustomerFailure.network,
      _ => CustomerFailure.server,
    };

    return CustomerException(
      failure: failure,
      message: e.message,
      statusCode: e.statusCode,
    );
  }
}
