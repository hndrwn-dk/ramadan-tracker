import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/support_provider.dart';
import 'package:ramadan_tracker/domain/support/support_prompt_policy.dart';
import 'package:ramadan_tracker/features/support/support_sheet.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Inline greeting on Today. Asks for support only when the policy allows it.
class SupportPromptSlot extends ConsumerStatefulWidget {
  const SupportPromptSlot({super.key});

  @override
  ConsumerState<SupportPromptSlot> createState() => _SupportPromptSlotState();
}

class _SupportPromptSlotState extends ConsumerState<SupportPromptSlot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushMoment());
  }

  void _pushMoment() {
    if (!mounted) return;
    final moment = ref.read(supportMomentProvider).asData?.value;
    if (moment == null) return;
    ref.read(supportPromptProvider).sync(
          milestone: moment.milestone,
          inLastTenNights: moment.inLastTenNights,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(supportMomentProvider, (previous, next) {
      final moment = next.asData?.value;
      if (moment == null) return;
      ref.read(supportPromptProvider).sync(
            milestone: moment.milestone,
            inLastTenNights: moment.inLastTenNights,
          );
    });
    final card = ref.watch(supportPromptProvider).card;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: card == null
          ? const SizedBox(width: double.infinity)
          : _SupportPromptCard(card: card),
    );
  }
}

class _SupportPromptCard extends ConsumerWidget {
  const _SupportPromptCard({required this.card});

  final ActiveSupportCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final greeting = switch (card.kind) {
      SupportMilestoneKind.dayTen => l10n.supportMilestoneDayTen,
      SupportMilestoneKind.eid => l10n.supportMilestoneEid,
      SupportMilestoneKind.sunnahTen => l10n.supportMilestoneSunnah,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurface(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (card.askVisible) ...[
              const SizedBox(height: 8),
              Text(
                l10n.supportAskBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => showSupportSheet(context),
                      child: Text(l10n.supportAskButton),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(supportPromptProvider).dismiss(),
                      child: Text(l10n.supportClose),
                    ),
                  ),
                ],
              ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref.read(supportPromptProvider).dismiss(),
                  child: Text(l10n.supportClose),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
