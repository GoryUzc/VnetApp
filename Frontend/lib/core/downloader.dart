import 'package:flutter/foundation.dart';
import 'mobile_downloader.dart'
    if (dart.library.html) 'web_downloader.dart'
    as downloader;

Future<void> downloadBytes(Uint8List bytes, String fileName) =>
    downloader.downloadBytes(bytes, fileName);
