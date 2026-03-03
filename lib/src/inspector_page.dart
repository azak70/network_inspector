import 'dart:convert';
import 'package:flutter/material.dart';
import 'inspector.dart';
import 'log_entry.dart';
import 'json_viewer.dart';

class NetworkInspectorPage extends StatefulWidget {
  const NetworkInspectorPage({super.key});
  @override
  State<NetworkInspectorPage> createState() => _NetworkInspectorPageState();
}

class _NetworkInspectorPageState extends State<NetworkInspectorPage> {
  @override
  void initState() {
    super.initState();
    NetworkInspector.instance.setInspectorOpen(true);
  }

  @override
  void dispose() {
    NetworkInspector.instance.setInspectorOpen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspector = NetworkInspector.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Inspector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: inspector.clear,
          )
        ],
      ),
      body: AnimatedBuilder(
        animation: inspector,
        builder: (context, _) {
          final entries = inspector.entries;
          if (entries.isEmpty) {
            return const Center(child: Text('No requests captured'));
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = entries[index];
              final status = e.statusCode?.toString() ?? '—';
              final dur = e.duration != null
                  ? '${e.duration!.inMilliseconds} ms'
                  : '…';
              return ListTile(
                title: Text('${e.method} ${e.uri.toString()}'),
                subtitle: Text('Status: $status   Time: $dur'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _InspectorDetail(entry: e),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InspectorDetail extends StatelessWidget {
  final NetworkLogEntry entry;
  const _InspectorDetail({required this.entry});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${entry.method} ${entry.uri.host}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestTab(entry: entry),
            _ResponseTab(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  final NetworkLogEntry entry;
  const _RequestTab({required this.entry});
  @override
  Widget build(BuildContext context) {
    final parsed = _tryParse(entry.requestBody);
    return ListView(
      children: [
        _Section(
          title: 'Info',
          child: SelectableText('${entry.method} ${entry.uri}', style: const TextStyle(fontFamily: 'monospace')),
        ),
        _Section(
          title: 'Headers',
          child: SelectableText(entry.requestHeaders?.toString() ?? ''),
        ),
        _Section(
          title: 'Body',
          child: parsed != null ? JsonViewer(data: parsed) : SelectableText('${entry.requestBody}'),
        ),
      ],
    );
  }

  dynamic _tryParse(dynamic body) {
    if (body == null) return null;
    if (body is String) {
      try {
        return json.decode(body);
      } catch (_) {
        return null;
      }
    }
    if (body is Map || body is List) return body;
    return null;
  }
}

class _ResponseTab extends StatelessWidget {
  final NetworkLogEntry entry;
  const _ResponseTab({required this.entry});
  @override
  Widget build(BuildContext context) {
    final text = entry.responseBodyUtf8;
    final parsed = _tryParse(text);
    return ListView(
      children: [
        _Section(
          title: 'Status',
          child: SelectableText('${entry.statusCode ?? ''} • ${entry.duration?.inMilliseconds ?? 0} ms', style: const TextStyle(fontFamily: 'monospace')),
        ),
        _Section(
          title: 'Headers',
          child: SelectableText(entry.responseHeaders?.toString() ?? ''),
        ),
        _Section(
          title: 'Body',
          child: parsed != null ? JsonViewer(data: parsed) : SelectableText(text),
        ),
      ],
    );
  }

  dynamic _tryParse(String text) {
    try {
      return json.decode(text);
    } catch (_) {
      return null;
    }
  }
}
