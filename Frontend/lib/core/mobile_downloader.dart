import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> downloadBytes(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);

  await file.writeAsBytes(bytes);

  // Abrir el archivo inmediatamente después de guardarlo
  await OpenFilex.open(filePath);
}
