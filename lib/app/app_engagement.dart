import 'package:flutter/material.dart';
import 'package:ramadan_tracker/app/app_store_config.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> shareApp(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  await Share.share(l10n.shareAppMessage(kPlayStoreWebUrl));
}

Future<void> openAppStoreListing() async {
  final marketUri = Uri.parse(kPlayStoreMarketUrl);
  if (await canLaunchUrl(marketUri)) {
    await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    return;
  }
  final webUri = Uri.parse(kPlayStoreWebUrl);
  await launchUrl(webUri, mode: LaunchMode.externalApplication);
}
