import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../demo_theme.dart';

/// Shows the result of an SDK call in a bottom sheet — a colour-coded title
/// (green on success, red on error), a scrollable monospace body, a Copy
/// action and a Close button. Mirrors the RN ResponseSheet.
Future<void> showResponseSheet(
  BuildContext context, {
  required String title,
  required String body,
  bool isError = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isError ? DemoColors.error : DemoColors.success,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: body.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: body));
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Response copied to clipboard.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                  child: const Text('Copy',
                      style: TextStyle(color: DemoColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  body.isEmpty ? '(no body)' : body,
                  style: const TextStyle(
                    fontFamily: kMonospace,
                    fontSize: 13,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFEFEF),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
