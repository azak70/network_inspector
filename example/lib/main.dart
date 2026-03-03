import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_inspector/network_inspector.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _makeRequest() async {
    final uri = Uri.parse('https://httpbin.org/get');
    final id = NetworkInspector.instance.startRequest(
      method: 'GET',
      uri: uri,
      headers: {'Accept': 'application/json'},
    );
    final res = await http.get(uri);
    NetworkInspector.instance.finishRequest(
      id: id,
      statusCode: res.statusCode,
      headers: res.headers,
      bodyBytes: res.bodyBytes,
    );
  }

  Future<void> _makeGraphQLLikeRequest() async {
    final uri = Uri.parse('https://example.com/graphql');
    final body = {'query': 'query { hello }', 'variables': {}};
    final id = NetworkInspector.instance.startRequest(
      method: 'GRAPHQL_QUERY',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    // Simulate a response
    final payload = {'data': {'hello': 'world'}};
    NetworkInspector.instance.finishRequest(
      id: id,
      statusCode: 200,
      headers: {'content-type': 'application/json'},
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Inspector Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _makeRequest,
              child: const Text('Make HTTP Request'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _makeGraphQLLikeRequest,
              child: const Text('Make GraphQL-like Request'),
            ),
          ],
        ),
      ),
    );
  }
}
