import 'dart:typed_data';
import 'dart:html' as html;


Future<void> downloadBytes(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob
(blob);
  (html.document.createElement('a') as dynamic)
    ..href = url
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
}