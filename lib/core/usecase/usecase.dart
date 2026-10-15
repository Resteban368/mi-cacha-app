/// Contrato base para casos de uso de la capa de dominio.
abstract interface class UseCase<T, Params> {
  Future<T> call(Params params);
}

final class NoParams {
  const NoParams();
}
