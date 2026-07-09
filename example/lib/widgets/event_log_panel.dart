import 'package:flutter/material.dart';

import '../demo_theme.dart';
import '../sdk_event_log.dart';

/// A dark, collapsible event-log panel pinned to the bottom of the home screen.
/// Listens to [SdkEventLog] and renders newest-first monospace lines, colour-
/// coded by level. Mirrors the RN event-log panel.
class EventLogPanel extends StatefulWidget {
  const EventLogPanel({super.key});

  @override
  State<EventLogPanel> createState() => _EventLogPanelState();
}

class _EventLogPanelState extends State<EventLogPanel> {
  bool _expanded = false;

  Color _lineColor(SdkEventLevel level) {
    switch (level) {
      case SdkEventLevel.success:
        return DemoColors.successDark;
      case SdkEventLevel.error:
        return DemoColors.errorDark;
      case SdkEventLevel.info:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DemoColors.logBg,
      child: AnimatedBuilder(
        animation: SdkEventLog.instance,
        builder: (context, _) {
          final events = SdkEventLog.instance.events;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  height: 48,
                  color: DemoColors.logHeader,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Event log (${events.length})',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: SdkEventLog.instance.clear,
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: events.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No events yet',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontFamily: kMonospace)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: events.length,
                          itemBuilder: (context, i) {
                            final e = events[i];
                            final detail = e.detail == null
                                ? ''
                                : ' — ${e.detail!.replaceAll('\n', ' ')}';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '[${formatLogTime(e.timestamp)}] ${e.title}$detail',
                                style: TextStyle(
                                  color: _lineColor(e.level),
                                  fontFamily: kMonospace,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
