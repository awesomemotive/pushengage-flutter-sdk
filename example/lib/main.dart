import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import 'demo_prefs.dart';
import 'demo_theme.dart';
import 'screens/alert_entry_screen.dart';
import 'screens/home_screen.dart';
import 'screens/send_goal_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/track_event_screen.dart';
import 'screens/trigger_campaign_entry_screen.dart';
import 'screens/trigger_campaigns_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Logging is a process-wide flag and needs no app id, so enable it up front.
  PushEngage.enableLogging(true);
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PushEngage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: DemoColors.primary,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AppBootstrap(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/sendGoal': (_) => const SendGoalScreen(),
        '/trackEvent': (_) => const TrackEventScreen(),
        '/triggerCampaigns': (_) => const TriggerCampaignsScreen(),
        '/triggerCampaignEntry': (_) => const TriggerCampaignEntryScreen(),
        '/alertEntry': (_) => const AlertEntryScreen(),
      },
    );
  }
}

/// Reads persisted config and pushes it into the SDK BEFORE the home screen
/// renders: `setEnvironment` then (only if configured) `setAppId`. Mirrors the
/// RN AppBootstrap. The native SDK initializes lazily on `setAppId`, so the
/// ordering matters (Android caches base URLs at init).
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final appId = await DemoPrefs.getAppId();
    final env = await DemoPrefs.getEnvironment();
    // setEnvironment MUST run before setAppId.
    await PushEngage.setEnvironment(env);
    if (DemoPrefs.isConfigured(appId)) {
      await PushEngage.setAppId(appId);
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: DemoColors.primary),
              SizedBox(height: 12),
              Text('Loading…', style: TextStyle(color: DemoColors.secondary)),
            ],
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}
