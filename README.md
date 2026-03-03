# chucker_flutter_inspector

[![Pub](https://img.shields.io/pub/v/chucker_flutter_inspector.svg)](https://pub.dev/packages/chucker_flutter_inspector)
[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

In-app HTTP and GraphQL inspector for Flutter apps. Captures requests and responses at the SDK layer and provides a compact viewer with collapsible JSON.

## Features
- Capture HTTP (GET/POST/DELETE/multipart) with headers, body, status, and timing
- Capture GraphQL queries and mutations (operation text, variables, data/errors)
- In-app inspector page with Request/Response tabs
- Collapsible JSON viewer for large/nested payloads
- Lightweight, flavor-agnostic; enable via a single flag

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  chucker_flutter_inspector: ^0.1.0
```

Or use a local path during development:

```yaml
dependencies:
  chucker_flutter_inspector:
  path: packages/chucker_flutter_inspector
```

## Quick Start

Render a floating button and open the inspector page:

```dart
import 'package:flutter/material.dart';
import 'package:chucker_flutter_inspector/network_inspector.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              bottom: kBottomNavigationBarHeight + 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NetworkInspectorPage()),
                  );
                },
                child: const Icon(Icons.http),
              ),
            ),
          ],
        );
      },
      home: const Placeholder(),
    );
  }
}
```

## Capture HTTP

Wrap your client calls with `startRequest` and `finishRequest`:

```dart
import 'package:http/http.dart' as http;
import 'package:chucker_flutter_inspector/network_inspector.dart';

Future<void> fetchProducts() async {
  final uri = Uri.parse('https://example.com/api/products');
  final logId = NetworkInspector.instance.startRequest(
    method: 'GET',
    uri: uri,
    headers: {'Accept': 'application/json'},
  );
  final response = await http.get(uri);
  NetworkInspector.instance.finishRequest(
    id: logId,
    statusCode: response.statusCode,
    headers: response.headers,
    bodyBytes: response.bodyBytes,
  );
}
```

## Capture GraphQL

Instrument your `GraphQLClient` calls similarly:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:chucker_flutter_inspector/network_inspector.dart';

Future<QueryResult> runQuery(GraphQLClient client, String query, Map<String, dynamic> variables) async {
  final id = NetworkInspector.instance.startRequest(
    method: 'GRAPHQL_QUERY',
    uri: Uri.parse('https://your-shopify-store/graphql'),
    headers: null,
    body: {'query': query, 'variables': variables},
  );
  final result = await client.query(QueryOptions(document: gql(query), variables: variables));
  final payload = result.data ?? {'exception': result.exception?.toString()};
  NetworkInspector.instance.finishRequest(
    id: id,
    statusCode: result.hasException ? 500 : 200,
    headers: null,
    bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
  );
  return result;
}
```

## Dio Integration

You can instrument Dio by intercepting requests and responses:

```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:chucker_flutter_inspector/network_inspector.dart';

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
```

## HttpClient Overrides

To capture low-level `dart:io` HttpClient traffic globally:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:chucker_flutter_inspector/network_inspector.dart';

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
    return _wrap(req, id);
  }

  HttpClientRequest _wrap(HttpClientRequest req, String id) {
    return _CapturingRequest(req, id);
  }

  // Delegate other methods to _base or implement similarly for post/put/delete...
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
    NetworkInspector.instance.finishRequest(
      id: _id,
      statusCode: res.statusCode,
      headers: res.headers.toMap().map((k, v) => MapEntry(k, v.join(','))),
      bodyBytes: Uint8List.fromList(bytes),
    );
    return _wrapResponse(res);
  }

  HttpClientResponse _wrapResponse(HttpClientResponse res) => res;

  // Delegate properties/methods to _req...
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  HttpOverrides.global = CapturingHttpOverrides();
  // runApp(...)
}
```

## Inspector Page

Use the built-in viewer:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const NetworkInspectorPage()),
);
```

The detail view shows Request and Response tabs with headers and a collapsible JSON body. Non-JSON bodies are displayed as raw text.

## Configuration
- Use app-level toggles to conditionally show the overlay button.
- The inspector keeps entries in memory; call `NetworkInspector.instance.clear()` to reset.
- To hide the overlay while the inspector page is open, watch `NetworkInspector.instance.inspectorOpen`.

## Example App
See `example/` for a minimal Flutter app showing integration.

## Publishing Checklist
- Update `pubspec.yaml`:
  - Remove `publish_to: "none"`
  - Set `version`, `description`, and `homepage/repository`
  - Add a `LICENSE` file (e.g., MIT) and `CHANGELOG.md`
- Verify:
  - `flutter pub publish --dry-run`
  - Ensure analyzer passes and README includes code samples
  - Confirm example app builds: `flutter run` from `example/`

## Branding
- Add your logo at `docs/logo.png` and include it in the README header if desired.

## Support & Contact
- GitHub: https://github.com/azak70/chucker_flutter_inspector
- Website: https://www.ahmetazak.com.tr
- Email: info@ahmetazak.com.tr
