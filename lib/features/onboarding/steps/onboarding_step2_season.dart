import 'package:flutter/material.dart';
import 'package:ramadan_tracker/widgets/adaptive_date_picker.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/ramadan_dates.dart';

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

  /// True when the start date was auto-filled from the Ramadan lookup table
  /// (so we can show an "approximate" hint).
  bool _prefilledFromTable = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // Prefill the start date from the next Ramadan in the lookup table so the
    // user only has to confirm. Falls back to today if out of table range.
    final suggested = RamadanDates.nextStartFrom(now);
    DateTime initialStart;
    if (widget.data.startDate != null) {
      initialStart = widget.data.startDate!;
    } else if (suggested != null) {
      initialStart = suggested;
      _prefilledFromTable = true;
    } else {
      initialStart = now;
    }
    _startDate = initialStart;
    _days = widget.data.days;

    final defaultLabel = 'Ramadan ${initialStart.year}';
    _labelController = TextEditingController(
      text: widget.data.seasonLabel.isEmpty ? defaultLabel : widget.data.seasonLabel,
    );

    // Persist prefilled values so a straight "Continue" keeps the suggestion.
    widget.data.startDate ??= initialStart;
    if (widget.data.seasonLabel.isEmpty) {
      widget.data.seasonLabel = _labelController.text;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    try {
      final picked = await showAdaptiveAppDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 730)),
      );
      if (picked != null && mounted) {
        setState(() {
          _startDate = picked;
          _prefilledFromTable = false;
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
    final isSmallScreen = MediaQuery.sizeOf(context).height < 600;

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
          SizedBox(height: isSmallScreen ? 16 : 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      TextField(
                        controller: _labelController,
                        decoration: InputDecoration(
                          hintText: l10n.ramadanYearHint(DateTime.now().year),
                          border: const OutlineInputBorder(),
                          isDense: isSmallScreen,
                        ),
                        onChanged: (value) {
                          widget.data.seasonLabel = value;
                        },
                        onTap: () {
                          if (_labelController.text.isEmpty || _labelController.text == 'Ramadan ${DateTime.now().year}') {
                            final now = DateTime.now();
                            _labelController.text = l10n.ramadanYearHint(now.year);
                            widget.data.seasonLabel = _labelController.text;
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
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
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            DropdownButtonFormField<int>(
                              value: _days,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                isDense: isSmallScreen,
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
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  isDense: isSmallScreen,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        DateFormat('MMM d, yyyy').format(_startDate),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
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
                  if (_prefilledFromTable) ...[
                    SizedBox(height: isSmallScreen ? 6 : 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'id'
                                ? 'Tanggal perkiraan. Sesuaikan dengan pengumuman setempat.'
                                : 'Estimated date. Adjust to match your local announcement.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.preview,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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

