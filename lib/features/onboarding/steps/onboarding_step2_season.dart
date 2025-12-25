import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final last10Start = _days - 9;
    final last10Date = _startDate.add(Duration(days: last10Start - 1));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ramadan Season',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Season Label',
              hintText: 'Ramadan 2025',
            ),
            onChanged: (value) {
              widget.data.seasonLabel = value;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _days,
                  decoration: const InputDecoration(
                    labelText: 'Days',
                  ),
                  items: const [
                    DropdownMenuItem(value: 29, child: Text('29 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                    ),
                    child: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                  ),
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
                    'Preview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Day 1 starts on ${DateFormat('MMM d, yyyy').format(_startDate)}.',
                  ),
                  Text(
                    'Last 10 nights begin on Day $last10Start (${DateFormat('MMM d, yyyy').format(last10Date)}).',
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
                  child: const Text('Back'),
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
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

