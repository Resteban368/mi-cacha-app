import 'package:dio/dio.dart';

import 'fake_http_adapter.dart';

/// Dio apuntando a una API simulada en memoria.
Dio apiDio(FakeHttpAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = adapter;
