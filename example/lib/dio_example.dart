import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:network_inspector/network_inspector.dart';

Future<void> runDioExample() async {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final id = NetworkInspector.instance.startRequest(
        method: options.method,
        uri: options.uri,
        headers: options.headers.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        body: options.data,
      );
      options.extra['inspector_id'] = id;
      handler.next(options);
    },
    onResponse: (response, handler) {
      final id = response.requestOptions.extra['inspector_id'] as String? ?? '';
      final bodyBytes = response.data is String
          ? Uint8List.fromList(utf8.encode(response.data))
          : Uint8List.fromList(utf8.encode(jsonEncode(response.data)));
      NetworkInspector.instance.finishRequest(
        id: id,
        statusCode: response.statusCode ?? 200,
        headers: response.headers.map.map((k, v) => MapEntry(k, v.join(','))),
        bodyBytes: bodyBytes,
      );
      handler.next(response);
    },
    onError: (e, handler) {
      final id = e.requestOptions.extra['inspector_id'] as String? ?? '';
      final payload = {'error': e.message, 'type': 'dio_error'};
      NetworkInspector.instance.finishRequest(
        id: id,
        statusCode: e.response?.statusCode ?? 500,
        headers: e.response?.headers.map.map((k, v) => MapEntry(k, v.join(','))),
        bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      );
      handler.next(e);
    },
  ));

  await dio.get('https://httpbin.org/get');
}
