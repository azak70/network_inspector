import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'log_entry.dart';

class NetworkInspector extends ChangeNotifier {
  static final NetworkInspector instance = NetworkInspector._();
  NetworkInspector._();

  final List<NetworkLogEntry> _entries = <NetworkLogEntry>[];
  final Map<String, NetworkLogEntry> _pending = <String, NetworkLogEntry>{};
  bool inspectorOpen = false;

  UnmodifiableListView<NetworkLogEntry> get entries =>
      UnmodifiableListView(_entries);

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';

  String startRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
  }) {
    final id = _newId();
    final entry = NetworkLogEntry(
      id: id,
      method: method.toUpperCase(),
      uri: uri,
      requestHeaders: headers,
      requestBody: body,
      startTime: DateTime.now(),
    );
    _pending[id] = entry;
    _entries.add(entry);
    notifyListeners();
    return id;
  }

  void finishRequest({
    required String id,
    required int statusCode,
    Map<String, String>? headers,
    Uint8List? bodyBytes,
  }) {
    if (id.isEmpty) return;
    final entry = _pending[id];
    if (entry == null) return;
    entry.statusCode = statusCode;
    entry.responseHeaders = headers;
    entry.responseBodyBytes = bodyBytes;
    entry.duration = DateTime.now().difference(entry.startTime);
    _pending.remove(id);
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    _pending.clear();
    notifyListeners();
  }

  void setInspectorOpen(bool value) {
    inspectorOpen = value;
    notifyListeners();
  }
}
