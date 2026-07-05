import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/settings_navigation.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Circular menu control — opens Settings from tab app bars.
class SettingsIconButton extends ConsumerWidget {
  final String? openSection;

  const SettingsIconButton({super.key, this.openSection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: isId ? 'Atur' : l10n.settings,
      onPressed: () => openSettingsScreen(context, ref, section: openSection),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.format_list_bulleted_rounded,
          size: 20,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
