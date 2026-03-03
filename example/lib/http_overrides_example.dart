import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:network_inspector/network_inspector.dart';

class CapturingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final base = super.createHttpClient(context);
    return _CapturingClient(base);
  }
}

class _CapturingClient implements HttpClient {
  final HttpClient _base;
  _CapturingClient(this._base);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final id = NetworkInspector.instance.startRequest(
      method: 'GET',
      uri: url,
    );
    final req = await _base.getUrl(url);
    return _CapturingRequest(req, id);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CapturingRequest implements HttpClientRequest {
  final HttpClientRequest _req;
  final String _id;
  _CapturingRequest(this._req, this._id);

  @override
  Future<HttpClientResponse> close() async {
    final res = await _req.close();
    final bytes = await consolidateHttpClientResponseBytes(res);
    final Map<String, String> headerMap = {};
    res.headers.forEach((name, values) {
      headerMap[name] = values.join(',');
    });
    NetworkInspector.instance.finishRequest(
      id: _id,
      statusCode: res.statusCode,
      headers: headerMap,
      bodyBytes: Uint8List.fromList(bytes),
    );
    return res;
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
