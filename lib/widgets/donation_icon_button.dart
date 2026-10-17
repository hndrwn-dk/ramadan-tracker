import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/support/support_sheet.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class DonationIconButton extends StatelessWidget {
  const DonationIconButton({super.key, this.iconButtonKey});

  final Key? iconButtonKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      key: iconButtonKey,
      tooltip: l10n.supportDeveloper,
      onPressed: () => showSupportSheet(context),
      icon: const Icon(Icons.volunteer_activism_outlined),
    );
  }
}
