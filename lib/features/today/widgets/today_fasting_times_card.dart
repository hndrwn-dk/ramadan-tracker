import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Premium Sahur / Iftar strip with live countdown to the next event.
class TodayFastingTimesCard extends StatefulWidget {
  final DateTime sahurTime;
  final DateTime iftarTime;
  final DateTime fajr;
  final DateTime maghrib;

  const TodayFastingTimesCard({
    super.key,
    required this.sahurTime,
    required this.iftarTime,
    required this.fajr,
    required this.maghrib,
  });

  @override
  State<TodayFastingTimesCard> createState() => _TodayFastingTimesCardState();
}

class _TodayFastingTimesCardState extends State<TodayFastingTimesCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h >= 1) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  _NextEvent _resolveNext(DateTime now) {
    if (now.isBefore(widget.sahurTime)) {
      return _NextEvent(
        labelKey: _NextLabel.sahur,
        target: widget.sahurTime,
        highlight: _Highlight.sahur,
      );
    }
    if (now.isBefore(widget.iftarTime)) {
      return _NextEvent(
        labelKey: _NextLabel.iftar,
        target: widget.iftarTime,
        highlight: _Highlight.iftar,
      );
    }
    return _NextEvent(
      labelKey: _NextLabel.sahur,
      target: widget.sahurTime.add(const Duration(days: 1)),
      highlight: _Highlight.sahur,
      isTomorrow: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final next = _resolveNext(now);
    final remaining = next.target.difference(now);
    final countdown = _formatCountdown(remaining);

    final headline = switch (next.labelKey) {
      _NextLabel.sahur when next.isTomorrow => l10n.sahurTomorrowIn(countdown),
      _NextLabel.sahur => l10n.sahurIn(countdown),
      _NextLabel.iftar => l10n.iftarIn(countdown),
    };

    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.42),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSurface.radius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    next.labelKey == _NextLabel.iftar
                        ? Icons.wb_twilight_rounded
                        : Icons.nights_stay_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.todayFastingCountdownLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.62),
                              letterSpacing: 0.2,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headline,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  countdown,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: scheme.primary,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _TimeColumn(
                      icon: Icons.nights_stay_outlined,
                      label: l10n.sahur,
                      time: widget.sahurTime,
                      sublabel: '${DateFormat('HH:mm').format(widget.fajr)} ${l10n.fajr}',
                      highlighted: next.highlight == _Highlight.sahur,
                    ),
                  ),
                  VerticalDivider(
                    width: 24,
                    thickness: 1,
                    color: AppSurface.borderColor(context),
                  ),
                  Expanded(
                    child: _TimeColumn(
                      icon: Icons.wb_twilight_outlined,
                      label: l10n.iftar,
                      time: widget.iftarTime,
                      sublabel:
                          '${DateFormat('HH:mm').format(widget.maghrib)} ${l10n.maghrib}',
                      highlighted: next.highlight == _Highlight.iftar,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NextLabel { sahur, iftar }

enum _Highlight { sahur, iftar }

class _NextEvent {
  final _NextLabel labelKey;
  final DateTime target;
  final _Highlight highlight;
  final bool isTomorrow;

  const _NextEvent({
    required this.labelKey,
    required this.target,
    required this.highlight,
    this.isTomorrow = false,
  });
}

class _TimeColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime time;
  final String sublabel;
  final bool highlighted;
  final bool alignEnd;

  const _TimeColumn({
    required this.icon,
    required this.label,
    required this.time,
    required this.sublabel,
    required this.highlighted,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cross =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.28)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSurface.nestedRadius),
        border: highlighted
            ? Border.all(color: scheme.primary.withValues(alpha: 0.22))
            : null,
      ),
      child: Column(
        crossAxisAlignment: cross,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('HH:mm').format(time),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
        ],
      ),
    );
  }
}

/// Shown when prayer location is not configured.
class TodayFastingTimesPlaceholder extends StatelessWidget {
  final VoidCallback? onEnableLocation;

  const TodayFastingTimesPlaceholder({super.key, this.onEnableLocation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.location_on_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.enableLocationForSahurIftar,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.todayFastingCountdownHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                ),
              ],
            ),
          ),
          if (onEnableLocation != null)
            TextButton(
              onPressed: onEnableLocation,
              child: Text(l10n.enableLocation),
            ),
        ],
      ),
    );
  }
}
