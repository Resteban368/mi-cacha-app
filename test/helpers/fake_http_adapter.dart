import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Respuesta simulada: `(status, body)`, o lanza para simular red caída.
typedef FakeHandler = (int, Object?) Function(RequestOptions options);

/// Adaptador HTTP en memoria para probar llamadas a la API sin red.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  FakeHandler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Simula que no hay conexión.
(int, Object?) offline(RequestOptions options) =>
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
