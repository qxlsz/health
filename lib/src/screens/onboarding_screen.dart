import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Devices'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            // Complete onboarding
            context.go('/dashboard');
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            context.go('/dashboard');
          }
        },
        steps: [
          _buildWelcomeStep(),
          _buildAppleWatchStep(),
          _buildAndroidStep(),
          _buildWhoopStep(),
        ],
      ),
    );
  }

  Step _buildWelcomeStep() {
    return Step(
      title: const Text('Welcome'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bedtime_outlined, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Connect Your Wearable Devices',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'This app helps you aggregate and analyze sleep data from multiple sources. '
            'You can connect:',
          ),
          const SizedBox(height: 16),
          _DeviceOption(
            icon: Icons.watch,
            name: 'Apple Watch',
            description: 'Via HealthKit (iOS only)',
          ),
          const SizedBox(height: 8),
          _DeviceOption(
            icon: Icons.watch,
            name: 'Android Wear',
            description: 'Via Health Connect (Android only)',
          ),
          const SizedBox(height: 8),
          _DeviceOption(
            icon: Icons.fitness_center,
            name: 'Whoop',
            description: 'Via OAuth API',
          ),
          const SizedBox(height: 16),
          const Card(
            color: Colors.blue,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your data is stored locally or on your self-hosted server. '
                      'We never sell or share your health data.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildAppleWatchStep() {
    return Step(
      title: const Text('Apple Watch'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.watch, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Connect Apple Watch via HealthKit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'To connect your Apple Watch:\n\n'
            '1. Grant permission to access HealthKit data\n'
            '2. Allow read access to Sleep Analysis data\n'
            '3. The app will sync your sleep data automatically\n\n'
            'Note: This feature is only available on iOS devices.',
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement HealthKit permission request in Phase 3
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HealthKit integration coming in Phase 3'),
                ),
              );
            },
            icon: const Icon(Icons.health_and_safety),
            label: const Text('Grant HealthKit Permission'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('I understand and consent to share HealthKit data'),
            value: false,
            onChanged: (value) {
              // Handle consent
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Step _buildAndroidStep() {
    return Step(
      title: const Text('Android Wear'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.watch, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Connect Android Wear via Health Connect',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'To connect your Android Wear device:\n\n'
            '1. Install Health Connect app (if not already installed)\n'
            '2. Grant permission to access Sleep Session data\n'
            '3. The app will sync your sleep data automatically\n\n'
            'Note: This feature is only available on Android devices.',
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement Health Connect permission request in Phase 3
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Health Connect integration coming in Phase 3'),
                ),
              );
            },
            icon: const Icon(Icons.health_and_safety),
            label: const Text('Grant Health Connect Permission'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('I understand and consent to share Health Connect data'),
            value: false,
            onChanged: (value) {
              // Handle consent
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Step _buildWhoopStep() {
    return Step(
      title: const Text('Whoop'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Connect Whoop via OAuth',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'To connect your Whoop device:\n\n'
            '1. Click the button below to authorize\n'
            '2. Log in to your Whoop account\n'
            '3. Grant permission to access sleep data\n'
            '4. The app will sync your sleep data automatically\n\n'
            'Note: You need a Whoop account and API access.',
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement Whoop OAuth in Phase 3
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Whoop OAuth integration coming in Phase 3'),
                ),
              );
            },
            icon: const Icon(Icons.link),
            label: const Text('Connect Whoop Account'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('I understand and consent to share Whoop data'),
            value: false,
            onChanged: (value) {
              // Handle consent
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      isActive: _currentStep >= 3,
    );
  }
}

class _DeviceOption extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;

  const _DeviceOption({
    required this.icon,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

