import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:logger/logger.dart';

class RegisterServiceUser {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> registerData,
  ) async {
    _logger.d('Creando nuevo Usuario');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('register')),
        headers: headers,
        body: jsonEncode(registerData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger.i(
          'Prospecto creado exitosamente (status ${response.statusCode})',
        );
        if (response.body.isEmpty) {
          return {
            'message': 'Prospecto creado exitosamente',
            'status': response.statusCode,
          };
        }
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
          return {'data': data, 'status': response.statusCode};
        } catch (_) {
          return {
            'message': 'Prospecto creado exitosamente',
            'raw': response.body,
            'status': response.statusCode,
          };
        }
      } else {
        if (response.statusCode == 422 ||
            response.statusCode == 400 ||
            response.statusCode == 409) {
          final details = _parseValidationErrors(response.body);
          throw Exception('422: $details');
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error en createProspect:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  String _parseValidationErrors(String body) {
    try {
      final data = jsonDecode(body);
      Map<String, dynamic>? errorsMap;
      if (data is Map<String, dynamic>) {
        if (data['errors'] is Map<String, dynamic>) {
          errorsMap = Map<String, dynamic>.from(data['errors']);
        } else {
          errorsMap = data;
        }
      }
      if (errorsMap == null) return body;

      final messages = <String>[];
      errorsMap.forEach((key, value) {
        if (value is List) {
          messages.add('$key: ${value.join(', ')}');
        } else if (value != null) {
          messages.add('$key: $value');
        }
      });
      return messages.isNotEmpty ? messages.join(' | ') : body;
    } catch (_) {
      return body;
    }
  }
}
