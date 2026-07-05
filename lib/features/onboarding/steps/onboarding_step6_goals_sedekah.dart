import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Step 7 of 9 — Sedekah daily goal (always shown; amount defaults to 0).
class OnboardingStep6GoalsSedekah extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStep6GoalsSedekah({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<OnboardingStep6GoalsSedekah> createState() =>
      _OnboardingStep6GoalsSedekahState();
}

class _OnboardingStep6GoalsSedekahState
    extends State<OnboardingStep6GoalsSedekah> {
  late TextEditingController _sedekahAmountController;

  static String _formatIdrAmount(int amount) {
    if (amount <= 0) return '';
    return NumberFormat('#,###', 'id_ID').format(amount);
  }

  static int _parseIdrAmount(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final amount = widget.data.sedekahAmount;
    _sedekahAmountController = TextEditingController(
      text: amount > 0
          ? (widget.data.sedekahCurrency == 'IDR'
              ? _formatIdrAmount(amount)
              : amount.toString())
          : '',
    );
  }

  @override
  void dispose() {
    _sedekahAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingGoalsSedekahTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.gentleGoalsBeatPerfectStreaks,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.setDailySedekahGoal),
            value: widget.data.sedekahGoalEnabled,
            onChanged: (value) {
              setState(() => widget.data.sedekahGoalEnabled = value);
            },
          ),
          if (widget.data.sedekahGoalEnabled) ...[
            const SizedBox(height: 8),
            Text(
              l10n.amount,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sedekahAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: l10n.enterAmount,
                border: const OutlineInputBorder(),
              ),
              inputFormatters: widget.data.sedekahCurrency == 'IDR'
                  ? [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      _IdrAmountInputFormatter(),
                    ]
                  : [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                widget.data.sedekahAmount = widget.data.sedekahCurrency == 'IDR'
                    ? _parseIdrAmount(value)
                    : (int.tryParse(value) ?? 0);
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.currency,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: widget.data.sedekahCurrency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'IDR', child: Text(l10n.idrRp)),
                DropdownMenuItem(value: 'SGD', child: Text(l10n.sgdSdollar)),
                DropdownMenuItem(value: 'USD', child: Text(l10n.usdDollar)),
                DropdownMenuItem(value: 'MYR', child: Text(l10n.myrRm)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    widget.data.sedekahCurrency = value;
                    if (value == 'IDR' && widget.data.sedekahAmount > 0) {
                      _sedekahAmountController.text =
                          _formatIdrAmount(widget.data.sedekahAmount);
                    } else if (value != 'IDR' &&
                        widget.data.sedekahAmount > 0) {
                      _sedekahAmountController.text =
                          widget.data.sedekahAmount.toString();
                    }
                  });
                }
              },
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onPrevious,
                  child: Text(l10n.back),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: widget.onNext,
                  child: Text(l10n.continueButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _IdrAmountInputFormatter extends TextInputFormatter {
  static final _idrFormat = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount == 0) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final formatted = _idrFormat.format(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
