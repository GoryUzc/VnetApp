import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:logger/logger.dart';

class MeetingService {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

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
        'Error en getAllMeetingUnassigned:',
        error: e,
        stackTrace: stackTrace,
      );
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
        throw 'Cita eliminado exitosamente: ${response.body}';
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
        throw 'Cita $idMeeting tomada con exito';
      } else if (response.statusCode == 409) {
        throw Exception('Cita Tomada por otro usuario: ${response.body}');
      } else {
        throw Exception('Error al tomar la cita: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en takeMeeting:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
