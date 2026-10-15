import '../../domain/entities/client_profile.dart';
import '../../domain/entities/customer_payload.dart';
import '../../domain/entities/customer_query.dart';
import '../../domain/entities/customers_page_result.dart';

abstract class BusinessCustomersDataSource {
  /// Obtiene los clientes paginados, el resumen métrico y el total.
  Future<CustomersPageResult> getCustomers(CustomerQuery query);

  /// Crea un nuevo cliente en el negocio.
  Future<ClientProfile> createCustomer(CustomerPayload payload);

  /// Actualiza un cliente existente por su ID.
  Future<ClientProfile> updateCustomer(String id, CustomerPayload payload);
}
