import 'package:flutter/material.dart';

class JsonViewer extends StatelessWidget {
  final dynamic data;
  const JsonViewer({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return _buildNode(context, data);
  }

  Widget _buildNode(BuildContext context, dynamic value) {
    if (value is Map) {
      return _MapNode(map: value);
    } else if (value is List) {
      return _ListNode(list: value);
    } else {
      return SelectableText(_stringify(value), style: const TextStyle(fontFamily: 'monospace'));
    }
  }

  String _stringify(dynamic v) {
    if (v == null) return 'null';
    return v.toString();
  }
}

class _MapNode extends StatelessWidget {
  final Map map;
  const _MapNode({required this.map});
  @override
  Widget build(BuildContext context) {
    final entries = map.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        return _ExpandableTile(
          title: e.key.toString(),
          child: JsonViewer(data: e.value),
        );
      }).toList(),
    );
  }
}

class _ListNode extends StatelessWidget {
  final List list;
  const _ListNode({required this.list});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(list.length, (i) {
        return _ExpandableTile(
          title: '[$i]',
          child: JsonViewer(data: list[i]),
        );
      }),
    );
  }
}

class _ExpandableTile extends StatefulWidget {
  final String title;
  final Widget child;
  const _ExpandableTile({required this.title, required this.child});
  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _expanded = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 22, top: 6, bottom: 6),
            child: widget.child,
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 150),
        ),
      ],
    );
  }
}
