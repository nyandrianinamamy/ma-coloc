import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HouseChoiceScreen extends StatelessWidget {
  const HouseChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to MaColoc!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get started with your household',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => context.go('/onboarding/create'),
                icon: const Icon(Icons.add_home),
                label: const Text('Create a House'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.go('/onboarding/join'),
                icon: const Icon(Icons.group_add),
                label: const Text('Join with Invite Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
