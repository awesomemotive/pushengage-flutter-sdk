import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_prefs.dart';
import '../demo_theme.dart';
import '../widgets/alert.dart';
import '../widgets/segmented_control.dart';

/// Configures the app id + environment, persists them, and pushes them into the
/// SDK (`setEnvironment` BEFORE `setAppId`). Mirrors the RN Settings screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _appIdCtl = TextEditingController();
  int _envIndex = 1; // 0 = STAGING, 1 = PRODUCTION
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _appIdCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final appId = await DemoPrefs.getAppId();
    final env = await DemoPrefs.getEnvironment();
    if (!mounted) return;
    setState(() {
      _appIdCtl.text = appId == DemoPrefs.defaultAppId ? '' : appId;
      _envIndex = env == Environment.staging ? 0 : 1;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final appId = _appIdCtl.text.trim();
    if (appId.isEmpty) {
      await showAlert(context, 'Invalid app id', 'App ID cannot be empty.');
      return;
    }
    setState(() => _saving = true);
    final env = _envIndex == 0 ? Environment.staging : Environment.production;
    try {
      await DemoPrefs.setAppId(appId);
      await DemoPrefs.setEnvironment(env);
      // setEnvironment MUST run before setAppId (Android caches base URLs).
      await PushEngage.setEnvironment(env);
      await PushEngage.setAppId(appId);
      if (!mounted) return;
      await showAlert(context, 'Saved',
          'Configuration saved. Force-quit and relaunch the app for the new app id to take effect.');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) await showAlert(context, 'Failed to save', e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DemoColors.screenBg,
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DemoColors.primary))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('APP CONFIGURATION',
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.6,
                          color: DemoColors.secondary)),
                  const SizedBox(height: 8),
                  const Text('App ID'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _appIdCtl,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(fontFamily: kMonospace),
                    decoration: const InputDecoration(
                      hintText: 'Paste your PushEngage site key',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The SDK caches the previous app id. After changing it, force-quit and relaunch the app.',
                    style: TextStyle(fontSize: 12, color: DemoColors.secondary),
                  ),
                  const SizedBox(height: 24),
                  const Text('ENVIRONMENT',
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.6,
                          color: DemoColors.secondary)),
                  const SizedBox(height: 8),
                  SegmentedControl(
                    labels: const ['STAGING', 'PRODUCTION'],
                    selectedIndex: _envIndex,
                    onChanged: (i) => setState(() => _envIndex = i),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Staging targets the PushEngage staging backend; Production targets the live backend.',
                    style: TextStyle(fontSize: 12, color: DemoColors.secondary),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DemoColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
