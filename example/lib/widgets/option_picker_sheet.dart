import 'package:flutter/material.dart';

import '../demo_theme.dart';

/// A bottom-sheet single-choice picker. Returns the chosen option, or `null`
/// if dismissed. Mirrors the RN AlertEntry type/availability pickers.
Future<String?> showOptionPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: DemoColors.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(option),
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      );
    },
  );
}
