import 'package:pdf_text/pdf_text.dart';

class PdfExtractor {
  static Future<String> extractTextFromPath(String path) async {
    final doc = await PDFDoc.fromPath(path);
    final text = await doc.text;
    return text;
  }
}