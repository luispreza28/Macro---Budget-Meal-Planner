import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';

/// Home page with navigation to main app features
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Macro + Budget Meal Planner'),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRouter.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Weekly Plan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('View and manage your 7-day meal plan'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go(AppRouter.plan),
                      child: const Text('View Plan'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_cart, size: 32),
                          const SizedBox(height: 8),
                          const Text('Shopping List', textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => context.go(AppRouter.shoppingList),
                            child: const Text('View'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.kitchen, size: 32),
                          const SizedBox(height: 8),
                          const Text('Pantry', textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => context.go(AppRouter.pantry),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Stage 1: Foundation Complete',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Basic app structure with routing, theming, and placeholder pages.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
