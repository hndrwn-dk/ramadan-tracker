import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step2_season.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step3_habits.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step4_goals.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class CreateSeasonFlow extends ConsumerStatefulWidget {
  const CreateSeasonFlow({super.key});

  @override
  ConsumerState<CreateSeasonFlow> createState() => _CreateSeasonFlowState();
}

class _CreateSeasonFlowState extends ConsumerState<CreateSeasonFlow> {
  int _currentStep = 0;
  int? _lastStep;

  OnboardingData _data = OnboardingData();

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return OnboardingStep2Season(
          key: const ValueKey(0),
          data: _data,
          onNext: _nextStep,
          onPrevious: () => Navigator.pop(context),
        );
      case 1:
        return OnboardingStep3Habits(
          key: const ValueKey(1),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 2:
        return OnboardingStep4Goals(
          key: const ValueKey(2),
          data: _data,
          onNext: _finish,
          onPrevious: _previousStep,
        );
      default:
        return OnboardingStep2Season(
          key: const ValueKey(0),
          data: _data,
          onNext: _nextStep,
          onPrevious: () => Navigator.pop(context),
        );
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _lastStep = _currentStep;
        _currentStep = _currentStep + 1;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _lastStep = _currentStep;
        _currentStep = _currentStep - 1;
      });
    }
  }

  Future<void> _finish() async {
    debugPrint('=== CreateSeasonFlow._finish() Started ===');
    try {
      debugPrint('Calling _data.save()...');
      await _data.save(ref);
      debugPrint('_data.save() completed successfully');

      ref.invalidate(allSeasonsProvider);
      ref.invalidate(currentSeasonProvider);

      if (mounted) {
        debugPrint('Navigating back with success...');
        Navigator.pop(context, true);
        debugPrint('=== CreateSeasonFlow._finish() Completed ===');
      } else {
        debugPrint('Widget not mounted, skipping navigation');
      }
    } catch (e, stackTrace) {
      debugPrint('=== ERROR in CreateSeasonFlow._finish() ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('=== End Error ===');
      if (mounted) {
        _showErrorDialog(context, e.toString(), () {
          if (mounted) Navigator.pop(context, false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createNewSeason),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    _buildProgressStep(0, AppLocalizations.of(context)!.date),
                    _buildProgressLine(_currentStep > 0),
                    _buildProgressStep(1, AppLocalizations.of(context)!.habits),
                    _buildProgressLine(_currentStep > 1),
                    _buildProgressStep(2, AppLocalizations.of(context)!.goals),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final int? childStep = (child.key is ValueKey<int>)
                          ? (child.key as ValueKey<int>).value
                          : null;

                      final bool isForward = _lastStep == null || _currentStep > _lastStep!;
                      final bool isIncoming = childStep == _currentStep;

                      final Animation<double> slideAnim =
                          isIncoming ? animation : ReverseAnimation(animation);

                      final Offset inBegin = Offset(isForward ? 0.1 : -0.1, 0.0);
                      final Offset outEnd = Offset(isForward ? -0.1 : 0.1, 0.0);

                      final Tween<Offset> tween = isIncoming
                          ? Tween<Offset>(begin: inBegin, end: Offset.zero)
                          : Tween<Offset>(begin: Offset.zero, end: outEnd);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: tween.animate(CurvedAnimation(
                            parent: slideAnim,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : Center(
                    child: Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive || isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: Text(l10n.seasonCreatedSuccessfully),
        content: Text(l10n.seasonCreatedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error, [VoidCallback? onClose]) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        title: Text(l10n.error),
        content: Text(l10n.seasonCreatedError(error)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onClose?.call();
            },
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

