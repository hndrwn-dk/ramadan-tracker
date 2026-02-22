import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class OnboardingStep4Goals extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStep4Goals({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<OnboardingStep4Goals> createState() => _OnboardingStep4GoalsState();
}

class _OnboardingStep4GoalsState extends State<OnboardingStep4Goals> {
  late TextEditingController _customPagesController;
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
    _customPagesController = TextEditingController(
      text: widget.data.customQuranPages.toString(),
    );
    final amount = widget.data.sedekahAmount;
    _sedekahAmountController = TextEditingController(
      text: amount > 0
          ? (widget.data.sedekahCurrency == 'IDR' ? _formatIdrAmount(amount) : amount.toString())
          : '',
    );
    // Auto-enable sedekah goal if sedekah habit is selected but toggle is off
    if (widget.data.selectedHabits.contains('sedekah') && !widget.data.sedekahGoalEnabled) {
      widget.data.sedekahGoalEnabled = true;
    }
  }

  @override
  void dispose() {
    _customPagesController.dispose();
    _sedekahAmountController.dispose();
    super.dispose();
  }

  int _calculateTotalPages() {
    if (widget.data.quranGoal == '1_khatam') {
      return 20 * widget.data.days;
    } else if (widget.data.quranGoal == '2_khatam') {
      return 40 * widget.data.days;
    } else {
      return widget.data.customQuranPages * widget.data.days;
    }
  }

  int _getDailyPages() {
    if (widget.data.quranGoal == '1_khatam') {
      return 20;
    } else if (widget.data.quranGoal == '2_khatam') {
      return 40;
    } else {
      return widget.data.customQuranPages;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasQuran = widget.data.selectedHabits.contains('quran_pages');
    final hasDhikr = widget.data.selectedHabits.contains('dhikr');
    final hasSedekah = widget.data.selectedHabits.contains('sedekah');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setGoals,
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
          if (hasQuran) ...[
            Text(
              l10n.quranGoal,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: Text(l10n.oneKhatam20Pages),
              value: '1_khatam',
              groupValue: widget.data.quranGoal,
              onChanged: (value) {
                setState(() {
                  widget.data.quranGoal = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.twoKhatam40Pages),
              value: '2_khatam',
              groupValue: widget.data.quranGoal,
              onChanged: (value) {
                setState(() {
                  widget.data.quranGoal = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.custom),
              value: 'custom',
              groupValue: widget.data.quranGoal,
              onChanged: (value) {
                setState(() {
                  widget.data.quranGoal = value!;
                });
              },
            ),
            if (widget.data.quranGoal == 'custom') ...[
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pagesPerDayLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ?? const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customPagesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: l10n.enterPages,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final pages = int.tryParse(value) ?? 20;
                        widget.data.customQuranPages = pages;
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 16),
                child: Text(
                  l10n.totalPagesCalculation(_calculateTotalPages(), _getDailyPages(), widget.data.days),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
          if (hasDhikr) ...[
            Text(
              l10n.dhikrTarget,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [33, 100, 300, 1000].map((preset) {
                return ChoiceChip(
                  label: Text('$preset'),
                  selected: widget.data.dhikrTarget == preset,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        widget.data.dhikrTarget = preset;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (hasSedekah) ...[
            SwitchListTile(
              title: Text(l10n.setDailySedekahGoal),
              value: widget.data.sedekahGoalEnabled,
              onChanged: (value) {
                setState(() {
                  widget.data.sedekahGoalEnabled = value;
                });
              },
            ),
            if (widget.data.sedekahGoalEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.amount,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ) ?? const TextStyle(
                                fontSize: 14,
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.currency,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ) ?? const TextStyle(
                                fontSize: 14,
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
                                  _sedekahAmountController.text = _formatIdrAmount(widget.data.sedekahAmount);
                                } else if (value != 'IDR' && widget.data.sedekahAmount > 0) {
                                  _sedekahAmountController.text = widget.data.sedekahAmount.toString();
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
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
                child: ElevatedButton(
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
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    final formatted = _idrFormat.format(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
