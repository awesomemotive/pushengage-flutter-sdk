import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

import '../demo_prefs.dart';
import '../demo_theme.dart';
import '../sdk_event_log.dart';
import '../widgets/config_card.dart';
import '../widgets/event_log_panel.dart';
import '../widgets/input_modal_sheet.dart';
import '../widgets/response_sheet.dart';

const _jsonIndent = JsonEncoder.withIndent('  ');

/// The demo's home hub — exercises the SDK via grouped action rows, surfaces
/// results in a ResponseSheet, and streams deep links / FCM errors / cold-boot
/// notifications into the event log. Mirrors the RN home screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _appId = DemoPrefs.defaultAppId;
  Environment _environment = Environment.production;
  String? _loading;
  FcmConfigError? _fcmError;

  StreamSubscription<Map<String, dynamic>?>? _deepLinkSub;
  StreamSubscription<FcmConfigError>? _fcmSub;

  @override
  void initState() {
    super.initState();
    _loadConfig();

    _deepLinkSub = PushEngage.deepLinkStream.listen((data) {
      SdkEventLog.instance.info(
        'Deep link received',
        '${data?['deepLink']}\n${jsonEncode(data?['data'])}',
      );
    });

    _fcmSub = PushEngage.onFcmConfigError.listen((e) {
      if (mounted) setState(() => _fcmError = e);
      SdkEventLog.instance.error('FCM Config Error (${e.code})', e.message);
    });

    _drainInitialNotification();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _fcmSub?.cancel();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final appId = await DemoPrefs.getAppId();
    final env = await DemoPrefs.getEnvironment();
    if (mounted) {
      setState(() {
        _appId = appId;
        _environment = env;
      });
    }
  }

  Future<void> _drainInitialNotification() async {
    final res = await PushEngage.getInitialNotification();
    if (res.isSuccess && res.data != null) {
      SdkEventLog.instance
          .success('Cold-boot notification captured', jsonEncode(res.data));
    } else {
      SdkEventLog.instance.info('Cold-boot notification',
          'none — app was not launched from a notification tap');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed('/settings');
    await _loadConfig();
  }

  // ---- execution helpers -------------------------------------------------

  String _unwrap(PushEngageResult result, {String? successText}) {
    if (result.isSuccess) {
      final data = result.data;
      if (data == null) return successText ?? 'OK';
      if (data is Map || data is List) return _jsonIndent.convert(data);
      return data.toString();
    }
    throw result.error ?? 'Unknown error';
  }

  Future<void> _run(
      String id, String title, Future<String> Function() invoke) async {
    setState(() => _loading = id);
    SdkEventLog.instance.info(title, 'started');
    try {
      final msg = await invoke();
      SdkEventLog.instance.success(title, 'OK');
      if (mounted) await showResponseSheet(context, title: title, body: msg);
    } catch (e) {
      SdkEventLog.instance.error(title, e.toString());
      if (mounted) {
        await showResponseSheet(context,
            title: title, body: e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  Future<void> _promptAndRun(
    String id,
    String title, {
    String? subtitle,
    String? placeholder,
    String initialValue = '',
    bool multiline = false,
    required Future<String> Function(String input) invoke,
  }) async {
    final input = await showInputSheet(context,
        title: title,
        subtitle: subtitle,
        placeholder: placeholder,
        initialValue: initialValue,
        multiline: multiline);
    if (input == null) return;
    await _run(id, title, () => invoke(input));
  }

  Map<String, dynamic> _parseJsonObject(String input) {
    final decoded = jsonDecode(input);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return decoded;
  }

  List<String> _splitCsv(String input) =>
      input.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  // ---- sections ----------------------------------------------------------

  List<_Section> _sections() => [
        _Section('Subscription', [
          _Action(
              'subscribe',
              'Subscribe',
              () => _run(
                  'subscribe',
                  'Subscribe',
                  () async => _unwrap(await PushEngage.subscribe(),
                      successText: 'Subscribed'))),
          _Action(
              'unsubscribe',
              'Unsubscribe',
              () => _run(
                  'unsubscribe',
                  'Unsubscribe',
                  () async => _unwrap(await PushEngage.unsubscribe(),
                      successText: 'Unsubscribed'))),
          _Action(
              'subStatus',
              'Get Subscription Status',
              () => _run('subStatus', 'Get Subscription Status', () async {
                    final r = await PushEngage.getSubscriptionStatus();
                    return _unwrap(r).toLowerCase() == 'true' || r.data == true
                        ? 'Subscribed'
                        : 'Not subscribed';
                  })),
          _Action(
              'subNotifStatus',
              'Get Subscription Notification Status',
              () =>
                  _run('subNotifStatus', 'Get Subscription Notification Status',
                      () async {
                    final r =
                        await PushEngage.getSubscriptionNotificationStatus();
                    return r.data == true
                        ? 'Can receive notifications'
                        : 'Cannot receive notifications';
                  })),
          _Action(
              'subId',
              'Get Subscriber ID',
              () => _run(
                  'subId',
                  'Get Subscriber ID',
                  () async => _unwrap(await PushEngage.getSubscriberId(),
                      successText: '(not available)'))),
          _Action(
              'initialNotif',
              'Get Initial Notification (cold-boot)',
              () => _run('initialNotif', 'Get Initial Notification', () async {
                    final r = await PushEngage.getInitialNotification();
                    return _unwrap(r,
                        successText:
                            '(none — drained, or app not launched from a notification)');
                  })),
        ]),
        _Section('Permissions', [
          _Action(
              'reqPerm',
              'Request Notification Permission',
              () =>
                  _run('reqPerm', 'Request Notification Permission', () async {
                    final r = await PushEngage.requestNotificationPermission();
                    return r.data == true ? 'granted' : 'denied';
                  })),
          _Action(
              'permStatus',
              'Get Notification Permission Status',
              () => _run(
                  'permStatus',
                  'Get Notification Permission Status',
                  () async => _unwrap(
                      await PushEngage.getNotificationPermissionStatus()))),
          _Action(
              'setBadge',
              'Set Badge Count',
              () => _promptAndRun('setBadge', 'Set Badge Count',
                      placeholder: 'e.g. 3',
                      initialValue: '3', invoke: (input) async {
                    final count = int.tryParse(input.trim());
                    if (count == null || count < 0) {
                      throw const FormatException(
                          'Enter a non-negative integer');
                    }
                    await PushEngage.setBadgeCount(count);
                    return 'Badge set to $count';
                  })),
          _Action(
              'clearBadge',
              'Clear Badge',
              () => _run('clearBadge', 'Clear Badge', () async {
                    await PushEngage.setBadgeCount(0);
                    return 'Cleared the badge';
                  })),
        ]),
        _Section('Profile & Attributes', [
          _Action(
              'addProfile',
              'Add Profile ID',
              () => _promptAndRun('addProfile', 'Add Profile ID',
                  initialValue: 'user_42',
                  invoke: (input) async =>
                      _unwrap(await PushEngage.addProfileId(input.trim())))),
          _Action(
              'subDetails',
              'Get Subscriber Details',
              () => _promptAndRun('subDetails', 'Get Subscriber Details',
                      subtitle:
                          'Comma-separated field names to fetch. Leave empty to fetch all fields.',
                      initialValue: 'first_name, email, profile_id, city',
                      invoke: (input) async {
                    // Empty input → empty list → all fields.
                    final fields = _splitCsv(input);
                    return _unwrap(
                        await PushEngage.getSubscriberDetails(fields),
                        successText: '(no details)');
                  })),
          _Action(
              'subAttrs',
              'Get Subscriber Attributes',
              () => _run(
                  'subAttrs',
                  'Get Subscriber Attributes',
                  () async =>
                      _unwrap(await PushEngage.getSubscriberAttributes()))),
          _Action(
              'addAttrs',
              'Add Subscriber Attributes',
              () => _promptAndRun('addAttrs', 'Add Subscriber Attributes',
                  multiline: true,
                  initialValue: '{"age":25,"city":"NY"}',
                  invoke: (input) async => _unwrap(
                      await PushEngage.addSubscriberAttributes(
                          _parseJsonObject(input))))),
          _Action(
              'setAttrs',
              'Set Subscriber Attributes',
              () => _promptAndRun('setAttrs', 'Set Subscriber Attributes',
                  multiline: true,
                  initialValue: '{"age":25,"city":"NY"}',
                  invoke: (input) async => _unwrap(
                      await PushEngage.setSubscriberAttributes(
                          _parseJsonObject(input))))),
          _Action(
              'delAttrs',
              'Delete Attributes',
              () => _promptAndRun('delAttrs', 'Delete Attributes',
                  initialValue: 'age, city',
                  invoke: (input) async => _unwrap(
                      await PushEngage.deleteSubscriberAttributes(
                          _splitCsv(input))))),
          _Action(
              'identify',
              'Identify',
              () => _promptAndRun('identify', 'Identify',
                      subtitle:
                          'Valid keys: first_name, last_name, email, phone, gender, dob, language, profile_id, country, city, state, zip',
                      multiline: true,
                      initialValue:
                          '{"email":"jane@example.com","profile_id":"user_42"}',
                      invoke: (input) async {
                    final m = _parseJsonObject(input);
                    return _unwrap(
                        await PushEngage.identify(IdentifyFields(
                          firstName: m['first_name'],
                          lastName: m['last_name'],
                          email: m['email'],
                          phone: m['phone'],
                          gender: m['gender'],
                          dob: m['dob'],
                          language: m['language'],
                          profileId: m['profile_id'],
                          country: m['country'],
                          city: m['city'],
                          state: m['state'],
                          zip: m['zip'],
                        )),
                        successText: 'Identified');
                  })),
          _Action(
              'logout',
              'Logout',
              () => _promptAndRun('logout', 'Logout',
                      subtitle:
                          'Comma-separated field names to remove. Leave empty to clear the default PII set.',
                      initialValue: 'email, profile_id', invoke: (input) async {
                    final names = _splitCsv(input);
                    return _unwrap(
                        await PushEngage.logout(names.isEmpty ? null : names),
                        successText: 'Logged out');
                  })),
        ]),
        _Section('Segments', [
          _Action(
              'addSeg',
              'Add Segment',
              () => _promptAndRun('addSeg', 'Add Segment',
                  initialValue: 'sports, news',
                  invoke: (input) async =>
                      _unwrap(await PushEngage.addSegment(_splitCsv(input))))),
          _Action(
              'removeSeg',
              'Remove Segments',
              () => _promptAndRun('removeSeg', 'Remove Segments',
                  initialValue: 'sports, news',
                  invoke: (input) async => _unwrap(
                      await PushEngage.removeSegment(_splitCsv(input))))),
          _Action(
              'addDynSeg',
              'Add Dynamic Segments',
              () => _promptAndRun('addDynSeg', 'Add Dynamic Segments',
                      multiline: true,
                      initialValue: '[{"name":"sports","duration":5}]',
                      invoke: (input) async {
                    final list = jsonDecode(input);
                    if (list is! List) {
                      throw const FormatException('Expected a JSON array');
                    }
                    final segments = list
                        .map((e) => DynamicSegment(
                            name: e['name'] as String,
                            duration: e['duration'] as int))
                        .toList();
                    return _unwrap(
                        await PushEngage.addDynamicSegment(segments));
                  })),
        ]),
        _Section('Goals & Events', [
          _Action('sendGoal', 'Send Goal',
              () => Navigator.of(context).pushNamed('/sendGoal')),
          _Action('trackEvent', 'Track Event',
              () => Navigator.of(context).pushNamed('/trackEvent')),
        ]),
        _Section('Triggers', [
          _Action('triggers', 'Trigger Campaigns',
              () => Navigator.of(context).pushNamed('/triggerCampaigns')),
        ]),
      ];

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DemoColors.screenBg,
      appBar: AppBar(
        backgroundColor: DemoColors.header,
        foregroundColor: Colors.white,
        title: const Text('PushEngage',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_fcmError != null) _buildBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ConfigCard(
                    appId: _appId,
                    environment: _environment,
                    onTap: _openSettings),
                for (final section in _sections()) _buildSection(section),
              ],
            ),
          ),
          const EventLogPanel(),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    final error = _fcmError!;
    return Container(
      width: double.infinity,
      color: DemoColors.error,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FCM Config Error (${error.code})',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(error.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _fcmError = null),
            child: const Text('Dismiss',
                style: TextStyle(
                    color: Colors.white, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(section.title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  color: DemoColors.secondary)),
        ),
        Card(
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              for (var i = 0; i < section.actions.length; i++) ...[
                _buildRow(section.actions[i]),
                if (i != section.actions.length - 1)
                  const Divider(height: 1, indent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_Action action) {
    final isLoading = _loading == action.id;
    return ListTile(
      title: Text(action.label, style: const TextStyle(fontSize: 15)),
      trailing: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chevron_right, color: DemoColors.chevron),
      onTap: _loading != null ? null : action.onTap,
    );
  }
}

class _Section {
  final String title;
  final List<_Action> actions;
  _Section(this.title, this.actions);
}

class _Action {
  final String id;
  final String label;
  final VoidCallback onTap;
  _Action(this.id, this.label, this.onTap);
}
