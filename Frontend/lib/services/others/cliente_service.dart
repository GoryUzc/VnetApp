import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:vnet_agenda/services/authentication/otp_service.dart';

Logger _logger = Logger();
OtpService _otpService = OtpService();

class ClienteService {
  Future<Map<String, dynamic>> getClient(String id) async {
    _logger.d('Obteniendo detalles del prospecto con ID: $id');
    try {
      final headers = await _otpService.getOtpHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('prospect/detail/$id')),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['prospect'] == null) {
          throw Exception('Prospecto no encontrado en la respuesta');
        }
        _logger.i('Detalles del prospecto obtenidos exitosamente');
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Prospecto no encontrado');
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor inicie sesión nuevamente');
      } else if (response.statusCode == 403) {
        throw Exception('No tiene permisos para ver este prospecto');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: $e');
    } on FormatException catch (e) {
      throw Exception('Error en el formato de respuesta: $e');
    } catch (e, stackTrace) {
      _logger.e('Error en getClient:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMeetingProspect(
    Map<String, dynamic> registerMeetingProspect,
  ) async {
    _logger.d('Creando nueva cita');

    try {
      final headers = await _otpService.getOtpHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('meeting/create')),
        headers: headers,
        body: jsonEncode(registerMeetingProspect),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger.i(
          'Prospecto creado exitosamente (status ${response.statusCode})',
        );
        if (response.body.isEmpty) {
          return {
            'message': 'Cita creada exitosamente',
            'status': response.statusCode,
          };
        }
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
          return {'data': data, 'status': response.statusCode};
        } catch (_) {
          return {
            'message': 'Cita creada exitosamente',
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
      _logger.e(
        'Error en createMeetingProspect:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
