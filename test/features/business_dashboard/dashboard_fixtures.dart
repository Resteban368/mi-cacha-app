/// Respuesta de `GET /business/dashboard?period=LAST_7_DAYS` (contrato).
Map<String, dynamic> dashboardJson() => {
  'period': {
    'type': 'LAST_7_DAYS',
    'from': '2026-10-09',
    'to': '2026-10-15',
    'days': 7,
    'previousFrom': '2026-10-02',
    'previousTo': '2026-10-08',
  },
  'currency': 'COP',
  'summary': {
    'reservations': {'value': 10, 'previous': 8, 'changePct': 25},
    'confirmed': 6,
    'completed': 2,
    'noShow': 1,
    'cancelled': 1,
    'collected': {'value': 400000, 'previous': 500000, 'changePct': -20},
    'booked': 800000,
    'pendingBalance': 300000,
    'pendingPayments': {'count': 2, 'amount': 90000},
    'occupancyPct': {'value': 20, 'previous': 0, 'changePct': null},
    'bookedHours': 14,
    'openHours': 70,
    'averageTicket': 100000,
    'newCustomers': {'value': 4, 'previous': 2, 'changePct': 100},
    'cancellationRate': 10,
    'noShowRate': 10,
    'discounts': 10000,
    'refunds': {'count': 1, 'amount': 50000},
  },
  'occupancyByCourt': [
    {
      'courtId': 'c1',
      'name': 'Sintética 1',
      'sport': 'FUTBOL',
      'reservations': 8,
      'bookedHours': 14,
      'openHours': 70,
      'occupancyPct': 20,
      'booked': 800000,
    },
  ],
  'byWeekday': [
    for (final (i, day) in [
      'SUNDAY',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
    ].indexed)
      {
        'dayOfWeek': day,
        'reservations': day == 'THURSDAY' ? 5 : i % 2,
        'booked': day == 'THURSDAY' ? 400000 : 0,
      },
  ],
  'heatmap': [
    {'dayOfWeek': 'THURSDAY', 'hour': 19, 'reservations': 5},
    {'dayOfWeek': 'FRIDAY', 'hour': 20, 'reservations': 2},
    {'dayOfWeek': 'MONDAY', 'hour': 8, 'reservations': 1},
  ],
  'heatmapMax': 5,
  'topCustomers': [
    {
      'id': 'cu1',
      'name': 'Laura Gómez',
      'phone': '+573001112233',
      'reservations': 4,
      'paid': 200000,
    },
  ],
  'paymentMethods': [
    {'code': 'NEQUI', 'name': 'Nequi', 'count': 3, 'amount': 300000, 'pct': 75},
    {
      'code': 'EFECTIVO',
      'name': 'Efectivo',
      'count': 1,
      'amount': 100000,
      'pct': 25,
    },
  ],
  'bySport': [
    {'sport': 'FUTBOL', 'reservations': 9, 'booked': 800000},
    {'sport': 'PADEL', 'reservations': 1, 'booked': 0},
  ],
  'sales': {
    'total': {'value': 200000, 'previous': 150000, 'changePct': 33},
    'walkIn': 50000,
    'consumptions': 150000,
    'count': 9,
    'units': 52,
    'averageConsumption': 18750,
    'pendingConsumptions': 40000,
    'topProducts': [
      {'productId': 'p1', 'name': 'Gatorade', 'units': 24, 'amount': 120000},
      {'productId': null, 'name': 'Agua', 'units': 20, 'amount': 50000},
    ],
    'byDay': [
      for (var d = 9; d <= 15; d++)
        {
          'date': '2026-10-$d',
          'walkIn': d == 14 ? 30000 : 0,
          'consumptions': d == 14 ? 90000 : (d == 11 ? 60000 : 0),
        },
    ],
  },
};
