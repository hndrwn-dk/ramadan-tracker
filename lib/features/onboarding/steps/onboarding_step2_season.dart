import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class OnboardingStep2Season extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStep2Season({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<OnboardingStep2Season> createState() => _OnboardingStep2SeasonState();
}

class _OnboardingStep2SeasonState extends State<OnboardingStep2Season> {
  late TextEditingController _labelController;
  late DateTime _startDate;
  late int _days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _labelController = TextEditingController(
      text: widget.data.seasonLabel.isEmpty ? 'Ramadan ${now.year}' : widget.data.seasonLabel,
    );
    _startDate = widget.data.startDate ?? now;
    _days = widget.data.days;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null && mounted) {
        setState(() {
          _startDate = picked;
        });
      }
    } catch (e) {
      // Handle date picker errors gracefully
      debugPrint('Error selecting date: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final last10Start = _days - 9;
    final last10Date = _startDate.add(Duration(days: last10Start - 1));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ramadanSeason,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.seasonLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ) ?? const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  hintText: l10n.ramadanYearHint(DateTime.now().year),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  widget.data.seasonLabel = value;
                },
                onTap: () {
                  // Update hint when field is empty
                  if (_labelController.text.isEmpty || _labelController.text == 'Ramadan ${DateTime.now().year}') {
                    final now = DateTime.now();
                    _labelController.text = l10n.ramadanYearHint(now.year);
                    widget.data.seasonLabel = _labelController.text;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.daysLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ?? const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _days,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 29, child: Text(l10n.daysCount(29))),
                        DropdownMenuItem(value: 30, child: Text(l10n.daysCount(30))),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _days = value;
                            widget.data.days = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.startDate,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ?? const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM d, yyyy').format(_startDate)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.preview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.day1StartsOn(DateFormat('MMM d, yyyy').format(_startDate)),
                  ),
                  Text(
                    l10n.last10NightsBeginOn(last10Start, DateFormat('MMM d, yyyy').format(last10Date)),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
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
                  onPressed: () {
                    widget.data.startDate = _startDate;
                    widget.data.days = _days;
                    widget.onNext();
                  },
                  child: Text(l10n.continueButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

