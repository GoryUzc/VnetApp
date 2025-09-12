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
}
