import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_theme.dart';
import '../sdk_event_log.dart';
import '../widgets/alert.dart';

/// Exercises the In-App Messaging surface: fires trigger events (with
/// optional JSON parameters) via `PushEngage.triggerIAMEvent` and
/// Custom-action button taps arrive on `PushEngage.onIAMCustomAction`
/// (subscribed on the home screen) and land in the event log. Mirrors the RN
/// InAppMessagingScreen.
class InAppMessagingScreen extends StatefulWidget {
  const InAppMessagingScreen({super.key});

  @override
  State<InAppMessagingScreen> createState() => _InAppMessagingScreenState();
}

class _InAppMessagingScreenState extends State<InAppMessagingScreen> {
  final TextEditingController _eventCtl = TextEditingController();
  final TextEditingController _paramsCtl = TextEditingController();
  bool _triggering = false;

  @override
  void dispose() {
    _eventCtl.dispose();
    _paramsCtl.dispose();
    super.dispose();
  }

  Future<void> _trigger() async {
    FocusScope.of(context).unfocus();
    final eventName = _eventCtl.text.trim();
    if (eventName.isEmpty) {
      await showAlert(context, 'Missing event name', 'Event name is required.');
      return;
    }

    Map<String, dynamic>? parameters;
    final paramsJson = _paramsCtl.text.trim();
    if (paramsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(paramsJson);
        if (decoded is! Map<String, dynamic>) {
          await showAlert(context, 'Invalid parameters',
              'Parameters must be a JSON object.');
          return;
        }
        parameters = decoded;
      } on FormatException catch (e) {
        await showAlert(context, 'Invalid JSON', e.message);
        return;
      }
    }

    setState(() => _triggering = true);
    final res = await PushEngage.triggerIAMEvent(eventName, parameters);
    if (!mounted) return;
    setState(() => _triggering = false);
    if (res.isSuccess) {
      SdkEventLog.instance.success('Trigger In-App Event', eventName);
      await showAlert(context, 'Success',
          'Event triggered. A matching in-app message (if any is synced and eligible) will display.');
    } else {
      final msg = res.error.toString();
      SdkEventLog.instance.error('Trigger In-App Event', msg);
      if (mounted) await showAlert(context, 'Trigger failed', msg);
    }
  }

  Widget _button(String label, bool loading, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: DemoColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _triggering ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('In-App Messaging',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Custom-action button taps arrive via '
              'PushEngage.onIAMCustomAction and are appended to the '
              'home-screen event log.',
              style: TextStyle(color: DemoColors.secondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _eventCtl,
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: 'Event name *',
                  hintText: 'e.g., onboarding_complete',
                  border: OutlineInputBorder(),
                  isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paramsCtl,
              autocorrect: false,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Parameters (JSON object)',
                  hintText: '{"step": "complete"}',
                  border: OutlineInputBorder(),
                  isDense: true),
            ),
            const SizedBox(height: 16),
            _button('Trigger In-App Event', _triggering, _trigger),
          ],
        ),
      ),
    );
  }
}
