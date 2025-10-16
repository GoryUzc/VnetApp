import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.100.196.1:8000/api/v1';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api/v1';
    } else {
      return 'http://10.100.196.206:8000/api/v1';
    }
  }

  static String endpoint(String path) {
    return '$baseUrl/${path.startsWith('/') ? path.substring(1) : path}';
  }
}
