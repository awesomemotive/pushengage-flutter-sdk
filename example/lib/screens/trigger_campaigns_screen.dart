import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_theme.dart';
import '../widgets/alert.dart';

/// Hub for trigger-campaign actions. Mirrors the RN TriggerCampaigns screen.
class TriggerCampaignsScreen extends StatefulWidget {
  const TriggerCampaignsScreen({super.key});

  @override
  State<TriggerCampaignsScreen> createState() => _TriggerCampaignsScreenState();
}

class _TriggerCampaignsScreenState extends State<TriggerCampaignsScreen> {
  bool _enabling = false;
  bool _disabling = false;

  Future<void> _automated(bool enable) async {
    setState(() => enable ? _enabling = true : _disabling = true);
    final res = await PushEngage.automatedNotification(
        enable ? TriggerStatusType.enabled : TriggerStatusType.disabled);
    if (!mounted) return;
    setState(() => enable ? _enabling = false : _disabling = false);
    await showAlert(
      context,
      res.isSuccess ? 'Success' : 'Error',
      res.isSuccess ? (res.data ?? 'OK') : res.error.toString(),
    );
  }

  Widget _button(String label, VoidCallback? onPressed,
      {bool loading = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: DemoColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('Trigger Campaigns',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _button('Send Trigger Event',
                () => Navigator.of(context).pushNamed('/triggerCampaignEntry')),
            _button('Add Alert',
                () => Navigator.of(context).pushNamed('/alertEntry')),
            _button('Enable Automated Notification',
                _enabling ? null : () => _automated(true),
                loading: _enabling),
            _button('Disable Automated Notification',
                _disabling ? null : () => _automated(false),
                loading: _disabling),
          ],
        ),
      ),
    );
  }
}
