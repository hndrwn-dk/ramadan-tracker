import 'package:flutter/material.dart';
import 'package:ramadan_tracker/app/donation_config.dart';
import 'package:ramadan_tracker/features/settings/webview_screen.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

Future<void> openDonationPage(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => WebViewScreen(
        url: kDonationUrl,
        title: l10n.supportDeveloper,
      ),
    ),
  );
}
