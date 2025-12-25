import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

class OnboardingStep1Welcome extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const OnboardingStep1Welcome({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nights_stay, size: 80, color: Colors.teal),
          const SizedBox(height: 32),
          Text(
            'Ramadan Tracker',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track your Ramadan in seconds',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No account • No ads • Stored on your device',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 48),
          _buildFeature(context, Icons.touch_app, 'One tap daily checklist'),
          const SizedBox(height: 16),
          _buildFeature(context, Icons.auto_awesome, 'Autopilot Qur\'an plan'),
          const SizedBox(height: 16),
          _buildFeature(context, Icons.notifications_active, 'Sahur & Iftar reminders (automatic)'),
          const Spacer(),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Start Setup'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Takes about 1 minute',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(child: Text(text)),
      ],
    );
  }
}
