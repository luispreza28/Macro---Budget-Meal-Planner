import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';

final ocrServiceProvider = Provider<OcrService>((_) => OcrService());

class OcrService {
  Future<String> ocrImage(File file) async {
    final rec = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFile(file);
      final out = await rec.processImage(input);
      return out.text;
    } finally { await rec.close(); }
  }

  /// Returns text per page for first [maxPages]
  Future<List<String>> ocrPdf(File pdf, {int maxPages = 4}) async {
    final doc = await PdfDocument.openFile(pdf.path);
    final pages = <String>[];
    try {
      final rec = TextRecognizer(script: TextRecognitionScript.latin);
      for (int i = 1; i <= doc.pagesCount && i <= maxPages; i++) {
        final page = await doc.getPage(i);
        final img = await page.render(width: 2000, height: (2000 * page.height / page.width).round());
        await page.close();
        if (img == null) continue;
        final tmp = File('${pdf.path}.$i.png')..writeAsBytesSync(img.bytes);
        final text = await rec.processImage(InputImage.fromFile(tmp));
        pages.add(text.text);
        try { tmp.deleteSync(); } catch (_) {}
      }
      await rec.close();
      return pages;
    } finally { await doc.close(); }
  }
}

