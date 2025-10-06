import 'dart:io';

/// Returns a temp directory without touching platform channels.
/// Uses dart:io's system temp (safe in unit/widget tests).
Future<Directory> ioTempDirProvider() async {
  return Directory.systemTemp.createTemp('csv_export_test_');
}
