import 'package:flutter/material.dart';

import 'coachmark_overlay.dart';
import 'coachmark_storage_keys.dart';
import 'staged_coachmark_service.dart';

const _config = CoachmarkConfig(
  keys: CoachmarkStorageKeys(prefix: 'support_coachmark'),
  firstShowMinAppOpens: 3,
  maxShowCount: 3,
  reminderDelays: [
    Duration(days: 7),
    Duration(days: 14),
  ],
);

class SupportCoachmark {
  SupportCoachmark._();

  static final _service = StagedCoachmarkService(config: _config);

  static Future<void> maybeShow({
    required BuildContext context,
    required GlobalKey targetKey,
    required VoidCallback onCta,
    required String title,
    required String body,
    required String dismissLabel,
    required String ctaLabel,
    StagedCoachmarkService? service,
  }) async {
    final coachmarkService = service ?? _service;
    if (!await coachmarkService.shouldShow()) return;
    if (!context.mounted) return;

    await coachmarkService.recordShown();
    if (!context.mounted) return;

    CoachmarkOverlay.show(
      context: context,
      targetKey: targetKey,
      title: title,
      body: body,
      dismissLabel: dismissLabel,
      ctaLabel: ctaLabel,
      onDismiss: () {},
      onCta: () async {
        await coachmarkService.recordCtaTapped();
        onCta();
      },
    );
  }
}
