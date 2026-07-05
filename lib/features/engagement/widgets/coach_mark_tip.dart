import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/services/coach_mark_service.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Dismissible one-time tip banner (KV-backed).
class CoachMarkTip extends ConsumerStatefulWidget {
  final String coachKey;
  final String message;

  const CoachMarkTip({
    super.key,
    required this.coachKey,
    required this.message,
  });

  @override
  ConsumerState<CoachMarkTip> createState() => _CoachMarkTipState();
}

class _CoachMarkTipState extends ConsumerState<CoachMarkTip> {
  bool _visible = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final seen = await CoachMarkService.isSeen(db, widget.coachKey);
    if (mounted) {
      setState(() {
        _visible = !seen;
        _loaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    final db = ref.read(databaseProvider);
    await CoachMarkService.markSeen(db, widget.coachKey);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_visible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                      ),
                ),
              ),
              IconButton(
                onPressed: _dismiss,
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.coachMarkDismiss,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
