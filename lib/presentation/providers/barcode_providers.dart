import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/barcode_mapping_service.dart';

final barcodeMapProvider = FutureProvider<Map<String, String>>(
  (ref) async => ref.read(barcodeMappingServiceProvider).getMap(),
);

final recentScansProvider = FutureProvider((ref) async =>
    ref.read(barcodeMappingServiceProvider).recent());

