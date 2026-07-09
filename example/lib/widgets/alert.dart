import 'package:flutter/material.dart';

/// A simple OK-only alert dialog (the Flutter analogue of RN's `Alert.alert`).
Future<void> showAlert(BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
