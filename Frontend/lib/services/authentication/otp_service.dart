import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/api_config.dart';

class OtpService {
  final Logger _logger = Logger();
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getConsultClient(
    String document,
    String typeDocument,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              ApiConfig.endpoint('/prospect/consult/$document/$typeDocument'),
            ),
            headers: {'Content-type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      _logger.d(
        'GET /prospect/consult/$document/$typeDocument -> ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta getConsultClient: $data');
        return data;
      } else {
        throw Exception('Error al obtener prospecto: ${response.body}');
      }
    } on TimeoutException catch (e, st) {
      _logger.e('Timeout en getConsultClient (15s)', error: e, stackTrace: st);
      throw Exception(
        'Tiempo de espera agotado al consultar el prospecto. Verifica tu conexión o el servidor.',
      );
    } on SocketException catch (e, st) {
      _logger.e(
        'Conexión rechazada en getConsultClient',
        error: e,
        stackTrace: st,
      );
      throw Exception(
        'No se pudo conectar al servidor (${ApiConfig.baseUrl}). Verifica IP/puerto y firewall.',
      );
    } catch (e, st) {
      _logger.e('Error en getConsultClient', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> sendToOtp(String email, String document) async {
    _logger.d('Enviando OTP a: $email con documento: $document');
    _logger.d('Obteniendo endpoint: ${ApiConfig.endpoint('send-otp')}');

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.endpoint('prospect/send-otp')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'document': document}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        throw Exception(
          'Respuesta del servidor vacía. Verifica el endpoint y CORS',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Estructura completa de la respuesta del login: $data');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e, st) {
      _logger.e('Error enviando OTP', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchActiveMeeting(String prospectId) async {
    try {
      final uri = Uri.parse(
        ApiConfig.endpoint('/meetings/prospect/consult/$prospectId'),
      );
      final resp = await http
          .get(uri, headers: await getOtpHeaders())
          .timeout(const Duration(seconds: 15));

      _logger.d(
        'GET meetings/prospects/consult/$prospectId -> ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _logger.d('Respuesta fetchActiveMeeting: $data');
        return data;
      } else {
        _logger.e('Error al obtener la reunión activa: ${resp.body}');
        return null;
      }
    } catch (e, st) {
      _logger.e('Error en fetchActiveMeeting', error: e, stackTrace: st);
      return null;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String otp,
    String email,
    String document,
  ) async {
    _logger.d(
      'Verificando OTP para: $email con documento: $document y OTP: $otp',
    );

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.endpoint('prospect/verify-email')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'document': document,
              'otp': otp,
            }),
          )
          .timeout(const Duration(seconds: 15));

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Respuesta cruda: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception(
          'Respuesta del servidor vacía. Verifica el endpoint y CORS',
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _logger.d('Estructura completa de la respuesta: $data');

        // Verificar la estructura de la respuesta
        if (data['token'] == null) {
          throw Exception('La respuesta no contiene token');
        }

        if (data['prospect'] == null) {
          throw Exception('La respuesta no contiene datos del prospecto');
        }

        // Guarda datos
        await _storage.write(key: 'token', value: data['token'].toString());

        // Guardar el ID del prospecto como string
        final prospectId = data['prospect']['id']?.toString();
        if (prospectId != null) {
          await _storage.write(key: 'prospect', value: prospectId);
          _logger.d('ID del prospecto guardado: $prospectId');

          final meetingData = await _fetchActiveMeeting(prospectId);

          return {
            'prospectId': prospectId,
            'hasMeeting': meetingData?['exists'] ?? false,
            'meeting': meetingData?['meeting'],
          };
          // Devuelve solo el ID como String
        } else {
          throw Exception('El prospecto no tiene ID válido');
        }
      } else {
        // Manejar errores del servidor
        final errorMsg =
            data['error'] ?? data['message'] ?? 'Error de autenticación';
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      _logger.e('Error en verifyOtp:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> getProspectId() async {
    return await _storage.read(key: 'prospect');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'prospect');
    _logger.i('Datos de sesión eliminados, usuario desconectado');
  }

  Future<Map<String, String>> getOtpHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
