import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/helper/pushengage_result.dart';
import 'package:pushengage_flutter_sdk/model/goal.dart';
import 'package:pushengage_flutter_sdk/model/trigger_campaign.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';
import 'package:pushengage_flutter_sdk_example/alert_entry.dart';
import 'package:pushengage_flutter_sdk_example/trigger_entry.dart';

class TriggerCampaignsPage extends StatefulWidget {
  const TriggerCampaignsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TriggerCampaignsPageState createState() => _TriggerCampaignsPageState();
}

class _TriggerCampaignsPageState extends State<TriggerCampaignsPage> {
  bool _isEnableLoading = false;
  bool _isDisableLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Trigger Campaigns'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => TriggerCampaignEntry()));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color.fromARGB(255, 34, 74, 219),
              ),
              child: const Text(
                'Send Trigger Event',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AlertEntryScreen()));
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 34, 74, 219)),
              child: const Text('Add Alert',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isEnableLoading
                  ? null
                  : () async {
                      setState(() => _isEnableLoading = true);
                      final res = await PushEngage.automatedNotification(
                          TriggerStatusType.enabled);
                      switch (res.status) {
                        case PushEngageResultStatus.success:
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.data.toString())));
                          break;
                        case PushEngageResultStatus.failure:
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.error.toString())));
                          break;
                      }

                      setState(() => _isEnableLoading = false);
                    },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 34, 74, 219)),
              child: _isEnableLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Enable Automated Notification',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDisableLoading
                  ? null
                  : () async {
                      setState(() => _isDisableLoading = true);
                      final res = await PushEngage.automatedNotification(
                          TriggerStatusType.disabled);
                      switch (res.status) {
                        case PushEngageResultStatus.success:
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.data.toString())));
                          break;
                        case PushEngageResultStatus.failure:
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.error.toString())));
                          break;
                      }

                      setState(() => _isDisableLoading = false);
                    },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 34, 74, 219)),
              child: _isDisableLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Disable Automated Notification',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
