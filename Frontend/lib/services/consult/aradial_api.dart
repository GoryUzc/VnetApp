import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AradialApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://10.245.51.11/api/v2';
    } else if (Platform.isAndroid) {
      return 'https://10.245.51.11/api/v2';
    } else if (Platform.isIOS) {
      return 'https://10.245.51.11/api/v2';
    } else {
      return 'https://10.245.51.11/api/v2';
    }
  }

  static String endpoint(String path) {
    return '$baseUrl/${path.startsWith('/') ? path.substring(1) : path}';
  }
}
