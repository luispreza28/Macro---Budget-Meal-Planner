import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/ingredient.dart';
import '../../providers/ingredient_providers.dart';
import '../../widgets/ingredients/ingredient_form.dart';

class IngredientEditPage extends ConsumerWidget {
  const IngredientEditPage({super.key, required this.ingredientId});

  final String ingredientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientAsync = ref.watch(ingredientByIdProvider(ingredientId));
    final saving = ref.watch(ingredientNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Ingredient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          if (saving) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
        ],
      ),
      body: ingredientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load ingredient: $e')),
        data: (ing) {
          if (ing == null) {
            return const Center(child: Text('Ingredient not found'));
          }
          return IngredientForm(
            ingredient: ing,
            onSubmit: (updated) async {
              await ref.read(ingredientNotifierProvider.notifier).updateIngredient(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingredient saved')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

