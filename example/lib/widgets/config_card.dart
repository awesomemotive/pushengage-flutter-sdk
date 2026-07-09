import 'package:flutter/material.dart';
import 'package:pushengage_flutter_sdk/model/environment.dart';

import '../demo_prefs.dart';
import '../demo_theme.dart';

/// A tappable card summarising the current environment + app id (tap to open
/// Settings). Mirrors the RN config card.
class ConfigCard extends StatelessWidget {
  final String appId;
  final Environment environment;
  final VoidCallback onTap;

  const ConfigCard({
    super.key,
    required this.appId,
    required this.environment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final configured = DemoPrefs.isConfigured(appId);
    final isStaging = environment == Environment.staging;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DemoColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ENVIRONMENT',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: DemoColors.secondary)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: isStaging
                      ? DemoColors.stagingChip
                      : DemoColors.productionChip,
                  child: Text(
                    environment.wireValue,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: DemoColors.divider),
            ),
            const Text('APP ID',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: DemoColors.secondary)),
            const SizedBox(height: 4),
            configured
                ? Text(appId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: kMonospace, color: Color(0xFF222222)))
                : const Text('Not configured · tap to set',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: DemoColors.error)),
          ],
        ),
      ),
    );
  }
}
