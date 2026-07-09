import 'package:flutter/material.dart';

import '../demo_theme.dart';

/// Prompts for a single text argument in a bottom sheet. Returns the entered
/// text on OK, or `null` on Cancel. The caller validates/parses the result.
/// Mirrors the RN input modal.
Future<String?> showInputSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? placeholder,
  String initialValue = '',
  bool multiline = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _InputSheet(
      title: title,
      subtitle: subtitle,
      placeholder: placeholder,
      initialValue: initialValue,
      multiline: multiline,
    ),
  );
}

class _InputSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? placeholder;
  final String initialValue;
  final bool multiline;

  const _InputSheet({
    required this.title,
    this.subtitle,
    this.placeholder,
    required this.initialValue,
    required this.multiline,
  });

  @override
  State<_InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<_InputSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: DemoColors.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.subtitle!,
                  style: const TextStyle(
                      fontSize: 13, color: DemoColors.secondary)),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              maxLines: widget.multiline ? null : 1,
              minLines: widget.multiline ? 6 : 1,
              style: const TextStyle(fontFamily: kMonospace, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: DemoColors.secondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DemoColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(88, 44),
                  ),
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
