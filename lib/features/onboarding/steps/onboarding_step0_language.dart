import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/platform_adaptive.dart';
import 'package:ramadan_tracker/data/providers/locale_provider.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/features/onboarding/widgets/onboarding_shared_widgets.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Step 1 of 9 — language must be chosen before continuing.
class OnboardingStep0Language extends ConsumerStatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const OnboardingStep0Language({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  ConsumerState<OnboardingStep0Language> createState() =>
      _OnboardingStep0LanguageState();
}

class _OnboardingStep0LanguageState extends ConsumerState<OnboardingStep0Language> {
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.data.selectedLanguageCode;
  }

  Future<void> _selectLanguage(String code) async {
    PlatformAdaptive.lightHaptic();
    await ref.read(localeProvider.notifier).setLocale(code);
    widget.data.selectedLanguageCode = code;
    setState(() => _selectedCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final canContinue = _selectedCode != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(child: OnboardingBrandMark(size: 44)),
          const SizedBox(height: 20),
          Text(
            l10n.languageTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingLanguageNudge,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 28),
          OnboardingLanguageOptionCard(
            code: 'EN',
            label: l10n.english,
            hint: l10n.languageOptionEnHint,
            selected: _selectedCode == 'en',
            onTap: () => _selectLanguage('en'),
          ),
          const SizedBox(height: 12),
          OnboardingLanguageOptionCard(
            code: 'ID',
            label: l10n.indonesian,
            hint: l10n.languageOptionIdHint,
            selected: _selectedCode == 'id',
            onTap: () => _selectLanguage('id'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canContinue ? widget.onNext : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.continueButton),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
