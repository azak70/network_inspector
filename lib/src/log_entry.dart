import 'dart:typed_data';

class NetworkLogEntry {
  final String id;
  final String method;
  final Uri uri;
  final Map<String, String>? requestHeaders;
  final Object? requestBody;
  final DateTime startTime;

  int? statusCode;
  Map<String, String>? responseHeaders;
  Uint8List? responseBodyBytes;
  Duration? duration;

  NetworkLogEntry({
    required this.id,
    required this.method,
    required this.uri,
    required this.requestHeaders,
    required this.requestBody,
    required this.startTime,
  });

  String get responseBodyUtf8 {
    if (responseBodyBytes == null) return '';
    try {
      return String.fromCharCodes(responseBodyBytes!);
    } catch (_) {
      return '';
    }
  }
}
