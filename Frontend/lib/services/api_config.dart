import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://10.245.51.11:8010/api/v1'; // ← Backend desarrollo
      // return 'http://localhost:8000/api/v1'; // ← Para web localhost
    } else if (Platform.isAndroid) {
      // Para DISPOSITIVO FÍSICO en misma red WiFi:
      // return 'http://192.168.137.1:8000/api/v1'; // ← IP de hotspot
      // O si estás en red normal:
      // return 'http://10.100.196.164:8000/api/v1'; // ← IP real de PC
      // Para DISPOSITIVO FÍSICO por USB:
      // return 'http://localhost:8000/api/v1';
      return 'http://10.245.51.11:8010/api/v1';
      // return 'http://127.0.0.1:8000/api/v1';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api/v1';
    } else {
      return 'http://localhost:8000/api/v1';
    }
  }

  static String endpoint(String path) {
    return '$baseUrl/${path.startsWith('/') ? path.substring(1) : path}';
  }
}
