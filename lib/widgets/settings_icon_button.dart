import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/settings_navigation.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class SettingsIconButton extends ConsumerWidget {
  final String? openSection;

  const SettingsIconButton({super.key, this.openSection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: isId ? 'Atur' : l10n.settings,
      onPressed: () => openSettingsScreen(context, ref, section: openSection),
    );
  }
}
