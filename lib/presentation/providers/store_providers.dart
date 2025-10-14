import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/store_profile.dart';
import '../../domain/services/store_profile_service.dart';

final storeProfilesProvider = FutureProvider<List<StoreProfile>>((ref) async {
  return ref.read(storeProfileServiceProvider).getProfiles();
});

final selectedStoreProvider =
    FutureProvider<StoreProfile?>((ref) async =>
        ref.read(storeProfileServiceProvider).getSelected());

