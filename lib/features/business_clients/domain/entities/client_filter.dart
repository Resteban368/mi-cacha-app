/// Tipo de filtro rápido (segmento) para la lista de clientes.
enum ClientFilterType {
  all('ALL', 'Todos'),
  vip('LOYAL', 'VIP / Frecuentes'),
  withDebt('WITH_DEBT', 'Con saldo pendiente'),
  newClients('NEW', 'Nuevos');

  const ClientFilterType(this.apiCode, this.label);

  final String apiCode;
  final String label;

  static ClientFilterType fromApiCode(String? code) {
    switch (code) {
      case 'LOYAL':
      case 'VIP':
        return ClientFilterType.vip;
      case 'WITH_DEBT':
        return ClientFilterType.withDebt;
      case 'NEW':
        return ClientFilterType.newClients;
      case 'ALL':
      default:
        return ClientFilterType.all;
    }
  }
}

/// Criterio de ordenamiento de clientes.
enum ClientSortBy {
  mostActive('MOST_RESERVATIONS', 'Más reservas'),
  topSpenders('TOP_SPENDERS', 'Mayor inversión'),
  recent('LAST_VISIT', 'Última visita'),
  highestDebt('HIGHEST_BALANCE', 'Mayor deuda'),
  nameAsc('NAME', 'Nombre (A-Z)'),
  newest('NEWEST', 'Más recientes');

  const ClientSortBy(this.apiCode, this.label);

  final String apiCode;
  final String label;

  static ClientSortBy fromApiCode(String? code) {
    switch (code) {
      case 'TOP_SPENDERS':
        return ClientSortBy.topSpenders;
      case 'LAST_VISIT':
        return ClientSortBy.recent;
      case 'HIGHEST_BALANCE':
        return ClientSortBy.highestDebt;
      case 'NAME':
        return ClientSortBy.nameAsc;
      case 'NEWEST':
        return ClientSortBy.newest;
      case 'MOST_RESERVATIONS':
      default:
        return ClientSortBy.mostActive;
    }
  }
}
