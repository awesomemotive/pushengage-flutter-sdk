import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_theme.dart';
import '../widgets/alert.dart';
import '../widgets/key_value_adder.dart';

/// Builds and sends a [TriggerCampaign] via `PushEngage.sendTriggerEvent`.
/// Mirrors the RN TriggerCampaignEntry screen.
class TriggerCampaignEntryScreen extends StatefulWidget {
  const TriggerCampaignEntryScreen({super.key});

  @override
  State<TriggerCampaignEntryScreen> createState() =>
      _TriggerCampaignEntryScreenState();
}

class _TriggerCampaignEntryScreenState
    extends State<TriggerCampaignEntryScreen> {
  final TextEditingController _campaignCtl = TextEditingController();
  final TextEditingController _eventCtl = TextEditingController();
  final TextEditingController _profileCtl = TextEditingController();
  final TextEditingController _referenceCtl = TextEditingController();
  Map<String, String> _data = {};
  bool _loading = false;

  @override
  void dispose() {
    _campaignCtl.dispose();
    _eventCtl.dispose();
    _profileCtl.dispose();
    _referenceCtl.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _done() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final campaign = TriggerCampaign(
      campaignName: _campaignCtl.text.trim(),
      eventName: _eventCtl.text.trim(),
      referenceId: _nullIfEmpty(_referenceCtl.text),
      profileId: _nullIfEmpty(_profileCtl.text),
      data: _data.isEmpty ? null : _data,
    );
    final res = await PushEngage.sendTriggerEvent(campaign);
    if (!mounted) return;
    setState(() => _loading = false);
    await showAlert(
      context,
      res.isSuccess ? 'Success' : 'Error',
      res.isSuccess
          ? (res.data ?? 'Trigger campaign added successfully')
          : res.error.toString(),
    );
  }

  Widget _field(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        autocorrect: false,
        decoration: InputDecoration(
            hintText: hint, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('Trigger Campaign',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Enter campaign name', _campaignCtl),
            _field('Enter event name', _eventCtl),
            _field('Enter profile id', _profileCtl),
            _field('Enter reference id', _referenceCtl),
            const SizedBox(height: 8),
            KeyValueAdder(onChanged: (m) => _data = m),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DemoColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                onPressed: _loading ? null : _done,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
