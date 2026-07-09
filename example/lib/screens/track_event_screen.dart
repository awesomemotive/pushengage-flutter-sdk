import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_theme.dart';
import '../widgets/alert.dart';

/// Builds and sends a [TrackEventPayload] via `PushEngage.trackEvent`. Mirrors
/// the RN TrackEvent screen.
class TrackEventScreen extends StatefulWidget {
  const TrackEventScreen({super.key});

  @override
  State<TrackEventScreen> createState() => _TrackEventScreenState();
}

class _TrackEventScreenState extends State<TrackEventScreen> {
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _dataCtl = TextEditingController();
  final TextEditingController _profileCtl = TextEditingController();
  final TextEditingController _providerCtl = TextEditingController();
  final TextEditingController _typeCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _dataCtl.dispose();
    _profileCtl.dispose();
    _providerCtl.dispose();
    _typeCtl.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _track() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      await showAlert(context, 'Missing eventName', 'Event name is required.');
      return;
    }

    Map<String, Object>? data;
    final dataStr = _dataCtl.text.trim();
    if (dataStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(dataStr);
        if (decoded is! Map) {
          await showAlert(
              context, 'Invalid data', 'Data must be a JSON object.');
          return;
        }
        data = Map<String, Object>.from(decoded);
      } catch (_) {
        await showAlert(context, 'Invalid JSON', 'Data is not valid JSON.');
        return;
      }
    }

    setState(() => _loading = true);
    final res = await PushEngage.trackEvent(TrackEventPayload(
      eventName: name,
      data: data,
      profileId: _nullIfEmpty(_profileCtl.text),
      provider: _nullIfEmpty(_providerCtl.text),
      eventType: _nullIfEmpty(_typeCtl.text),
    ));
    if (!mounted) return;
    setState(() => _loading = false);
    await showAlert(
      context,
      res.isSuccess ? 'Success' : 'Track event failed',
      res.isSuccess ? 'Event tracked.' : res.error.toString(),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {String? hint, bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autocorrect: false,
          maxLines: multiline ? null : 1,
          minLines: multiline ? 4 : 1,
          decoration: InputDecoration(
              hintText: hint, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('Track Event',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Event name *', _nameCtl, hint: 'e.g., MySite.AddToCart'),
            _field('Data (JSON object)', _dataCtl,
                hint: '{"product_id": "123", "qty": 2}', multiline: true),
            _field('Profile ID', _profileCtl, hint: 'Optional'),
            _field('Provider', _providerCtl, hint: 'Defaults to "PushEngage"'),
            _field('Event type', _typeCtl,
                hint: 'Defaults to "PushEngage.CustomEvent"'),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DemoColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _loading ? null : _track,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Track Event'),
            ),
          ],
        ),
      ),
    );
  }
}
