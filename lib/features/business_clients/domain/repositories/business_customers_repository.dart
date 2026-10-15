import '../entities/client_profile.dart';
import '../entities/customer_payload.dart';
import '../entities/customer_query.dart';
import '../entities/customers_page_result.dart';

abstract class BusinessCustomersRepository {
  /// Obtiene el directorio de clientes paginado con métricas y resumen.
  Future<CustomersPageResult> getCustomers(CustomerQuery query);

  /// Crea un nuevo cliente en el negocio.
  Future<ClientProfile> createCustomer(CustomerPayload payload);

  /// Actualiza los datos de un cliente existente.
  Future<ClientProfile> updateCustomer(String id, CustomerPayload payload);
}
