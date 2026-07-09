import 'package:flutter/material.dart';

import '../demo_theme.dart';

/// A "Key / Value" adder row plus a removable list of the entries added.
/// Reports the assembled map to [onChanged]. Shared by the Trigger Campaign
/// and Alert entry screens. Mirrors the RN key/value adder.
class KeyValueAdder extends StatefulWidget {
  final ValueChanged<Map<String, String>> onChanged;

  const KeyValueAdder({super.key, required this.onChanged});

  @override
  State<KeyValueAdder> createState() => _KeyValueAdderState();
}

class _KeyValueAdderState extends State<KeyValueAdder> {
  final List<MapEntry<String, String>> _entries = [];
  final TextEditingController _keyCtl = TextEditingController();
  final TextEditingController _valCtl = TextEditingController();

  @override
  void dispose() {
    _keyCtl.dispose();
    _valCtl.dispose();
    super.dispose();
  }

  void _notify() =>
      widget.onChanged({for (final e in _entries) e.key: e.value});

  void _add() {
    final k = _keyCtl.text.trim();
    final v = _valCtl.text.trim();
    if (k.isEmpty || v.isEmpty) return;
    setState(() {
      _entries.add(MapEntry(k, v));
      _keyCtl.clear();
      _valCtl.clear();
    });
    _notify();
  }

  void _remove(int index) {
    setState(() => _entries.removeAt(index));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Enter Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _keyCtl,
                autocorrect: false,
                decoration: const InputDecoration(
                    hintText: 'Key',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _valCtl,
                autocorrect: false,
                decoration: const InputDecoration(
                    hintText: 'Value',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DemoColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _add,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            itemCount: _entries.length,
            itemBuilder: (context, i) {
              final e = _entries[i];
              return Row(
                children: [
                  Expanded(
                    child: Text('${e.key} : ${e.value}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () => _remove(i),
                    child: const Text('Cancel',
                        style: TextStyle(color: DemoColors.destructive)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
