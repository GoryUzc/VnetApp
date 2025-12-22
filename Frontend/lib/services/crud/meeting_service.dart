import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/authentication/otp_service.dart';

class MeetingService {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  final OtpService _otpService = OtpService();

  Future<List<Map<String, dynamic>>> getAllMeeting() async {
    _logger.d('Obteniendo lista de Citas');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/meetings/list')),
        headers: headers,
      );
      _logger.d('Codigo de estado : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista usuarios: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['meetings'] is List)
                ? data['meetings'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Citas obtenidos exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener citas: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getAllMeeting:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMeetingUnassigned() async {
    _logger.d('Obteniendo citas sin asignar');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/meetings/list/unassigned')),
        headers: headers,
      );
      _logger.d('Codigo de estado : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista de citas sin asignar: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['meetings'] is List)
                ? data['meetings'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Citas obtenidas exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener usuarios: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getAllMeetingUnassigned:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMeetingAssigned() async {
    _logger.d('Obteniendo citas asignadas');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/meetings/list/assigned')),
        headers: headers,
      );
      _logger.d('Codigo de estado : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista de citas sin asignar: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['meetings'] is List)
                ? data['meetings'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Citas obtenidas exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getAllMeetingUnassigned:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMeetingUser() async {
    _logger.d('Obteniendo citas del Usuario');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/meetings/user')),
        headers: headers,
      );
      _logger.d('Codigo de estado : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista de citas del usuario: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['meetings'] is List)
                ? data['meetings'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Citas obtenidas exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getAllMeetingUser:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMeetingUserProcess() async {
    _logger.d('Obteniendo citas del Usuario en proceso');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/meetings/user/process')),
        headers: headers,
      );
      _logger.d('Codigo de estado : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista de citas del usuario en proceso: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['meetings'] is List)
                ? data['meetings'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Citas obtenidas exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getAllMeetingUserProcess:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMeetingEnd() async {
    _logger.d('Obteniendo citas finalizadas');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/meetings/list/end')),
        headers: headers,
      );
      _logger.d('Codigo de estado : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista de citas finalizadas: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['meetings'] is List)
                ? data['meetings'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Citas obtenidas exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getAllMeetingEnd:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMeetingDetails(String id) async {
    _logger.d('Obteniendo detalles de la cita: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/meetings/detail/$id')),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meeting =
            (data is Map<String, dynamic> && data['meeting'] is Map)
                ? Map<String, dynamic>.from(data['meeting'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Detalles de la cita obtenidos exitosamente');
        return meeting;
      } else {
        throw Exception(
          'Error al obtener detalles de la cita: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getMeetingDetails:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMeetingContractProspect(String id) async {
    _logger.d('Obteniendo detalles de la cita: $id');

    try {
      final headers = await _otpService.getOtpHeaders();
      final response = await http
          .get(
            Uri.parse(ApiConfig.endpoint('/meetings/prospect/contract/$id')),
            headers: headers,
          )
          .timeout(const Duration(seconds: 120)); // ← timeout para móvil

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        _logger.i('Detalles de la cita obtenidos exitosamente');
        return data;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('El servidor no responde. Intente más tarde.');
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getMeetingContractProspect:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMeetingDetailProspect(
    String idMeeting,
    String idProspect,
  ) async {
    try {
      final headers = await _otpService.getOtpHeaders();
      final response = await http.get(
        Uri.parse(
          ApiConfig.endpoint(
            '/meetings/prospect/detail/$idMeeting/$idProspect',
          ),
        ),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meeting =
            (data is Map<String, dynamic> && data['meeting'] is Map)
                ? Map<String, dynamic>.from(data['meeting'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Detalles de la cita obtenidos exitosamente');
        return meeting;
      } else {
        throw Exception(
          'Error al obtener detalles de la cita: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getMeetingDetails:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMeeting(
    Map<String, dynamic> meetingData,
  ) async {
    _logger.d('Creando cita');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('/meetings/create')),
        headers: headers,
        body: jsonEncode(meetingData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final meeting =
            (data is Map<String, dynamic> && data['meeting'] is Map)
                ? Map<String, dynamic>.from(data['meeting'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Cita creado exitosamente');
        return meeting;
      } else if (response.statusCode == 422) {
        throw Exception('Validación: ${response.body}');
      } else {
        throw Exception('Error al crear cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en createMeeting:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMeeting(
    String id,
    Map<String, dynamic> dataMeeting,
  ) async {
    _logger.d('Actualizando cita: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('meetings/update/$id')),
        headers: headers,
        body: jsonEncode(dataMeeting),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meeting =
            (data is Map<String, dynamic> && data['meeting'] is Map)
                ? Map<String, dynamic>.from(data['meeting'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Cita actualizado exitosamente');
        return meeting;
      } else if (response.statusCode == 422) {
        throw Exception('Validación: ${response.body}');
      } else {
        throw Exception('Error al actualizar cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en updateMeeting:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteMeeting(String id) async {
    _logger.d('Eliminando cita: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.endpoint('meetings/delete/$id')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _logger.i('Cita eliminado exitosamente: ${response.body}');
      } else {
        throw Exception('Error al eliminar cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en deleteMeeting:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> takeMeeting(String idMeeting) async {
    _logger.d('Tomando Cita de instalacion $idMeeting');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('/meetings/take/$idMeeting')),
        headers: headers,
      );
      if (response.statusCode == 201) {
        _logger.i('Cita $idMeeting tomada con exito');
      } else if (response.statusCode == 409) {
        _logger.i('Cita Tomada por otro usuario: ${response.body}');
      } else {
        throw Exception('Error al tomar la cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en takeMeeting:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //  Consultar si el prospecto tiene cita activa */
  Future<Map<String, dynamic>?> fetchActiveMeeting(String prospectId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final uri = Uri.parse(
        ApiConfig.endpoint('/api/meetings/prospect/$prospectId'),
      );
      final resp = await http.get(uri, headers: headers);

      _logger.d('GET /api/meetings/prospect/$prospectId → ${resp.statusCode}');

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body); // {"exists":true,"meeting":{...}}
      }
      // 404 o cualquier otro código => no hay cita
      return null;
    } catch (e, st) {
      _logger.e('Error en fetchActiveMeeting', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> cancelMeeting(
    String meetingId,
    String observation,
    String status,
  ) async {
    try {
      final headers = await _otpService.getOtpHeaders();
      final resp = await http.put(
        Uri.parse(
          ApiConfig.endpoint('/meetings/prospect/changestatus/$meetingId'),
        ),
        headers: headers,
        body: jsonEncode({
          'status': status.trim(),
          'observation': observation.trim(),
        }),
      );

      _logger.d('Response → ${resp.statusCode}');

      if (resp.statusCode != 201) {
        throw Exception('Error al cancelar: ${resp.body}');
      }
      _logger.i('Cita $meetingId cancelada');
    } catch (e, st) {
      _logger.e('Error en cancelMeeting', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> initMeeting(String id) async {
    _logger.d('Iniciando cita de instalacion $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('/meetings/updated/status/init/$id')),
        headers: headers,
      );
      if (response.statusCode == 201) {
        _logger.i('Cita $id iniciada con exito');
      } else {
        throw Exception('Error al iniciar la cita ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.d('Error en initMeeting:', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> endMeeting(String id) async {
    _logger.d('Finalizando instalacion $id');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('/meetings/updated/status/end/$id')),
        headers: headers,
      );
      if (response.statusCode == 201) {
        _logger.i('Cita $id Finalizada con exito');
      } else {
        throw Exception('Error al fializar la cita ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.d('Error en initMeeting:', error: e, stackTrace: stackTrace);
    }
  }
}
