import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_page.dart';

/// Thin wrapper to expose the onboarding flow under a distinct class name.
/// Keeps compatibility with specs expecting `OnboardingFlowPage`.
class OnboardingFlowPage extends ConsumerWidget {
  const OnboardingFlowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const OnboardingPage();
  }
}

