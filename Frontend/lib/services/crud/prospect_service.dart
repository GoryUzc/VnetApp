import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:logger/logger.dart';

class ProspectService {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  Future<List<dynamic>> getAllProspects() async {
    _logger.d('Obteniendo lista de prospectos');

    try {
      final headers = await _authService.getAuthHeaders();
      _logger.d('Headers de autenticacion: $headers');

      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('prospects/list')),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      //Manejo especifico de errores de autenticacion/autorizacion

      if (response.statusCode == 401) {
        _logger.w('No autorizado - Token expirado o invalido');
        throw Exception('Sesion expirada. Por favor inicie sesion nuevamente ');
      }

      if (response.statusCode == 403) {
        _logger.w('Acceso prohibido - El usuario no tiene permisos');
        throw Exception('El usuario no tiene permisos para esta funcion');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Prospects obtenidos exitosamente');

        //Manejo de diferentes tipos de respuesta
        if (data is List) {
          return data;
        } else if (data.containsKey('prospects') && data['prospects'] is List) {
          return data['prospects'];
        } else if (data.containsKey('data') && data['data'] is List) {
          return data['data']; // Para respuesta paginada
        } else {
          _logger.w('Formato de respuesta inesperado');
          return [data]; // Tratar como lista de un elemento
        }
      } else {
        throw Exception('Error al obtener prospects: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getAllProspects:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProspectDetails(String id) async {
    _logger.d('Obteniendo detalles del prospecto: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('prospects/detail/$id')),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Detalles del prospecto obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener detalles del prospecto: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getProspectDetails:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createProspect(
    Map<String, dynamic> prospectData,
  ) async {
    _logger.d('Creando nuevo prospecto');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('prospects/create')),
        headers: headers,
        body: jsonEncode(prospectData),
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

  Future<Map<String, dynamic>> updateProspect(
    String id,
    Map<String, dynamic> prospectData,
  ) async {
    _logger.d('Actualizando prospecto: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('prospects/update/$id')),
        headers: headers,
        body: jsonEncode(prospectData),
      );

      if (response.statusCode == 201) {
        _logger.i(
          'Prospecto actualizado exitosamente (status ${response.statusCode})',
        );
        if (response.body.isEmpty) {
          return {
            'message': 'Prospecto actualizado exitosamente',
            'status': response.statusCode,
          };
        }
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
          return {'data': data, 'status': response.statusCode};
        } catch (_) {
          return {
            'message': 'Prospecto actualizado exitosamente',
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
      _logger.e('Error en updateProspect:', error: e, stackTrace: stackTrace);
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

  Future<void> deleteProspect(String id) async {
    _logger.d('Eliminando prospecto: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.endpoint('prospects/delete/$id')),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar prospecto: ${response.body}');
      }
      _logger.i('Prospecto eliminado exitosamente');
    } catch (e, stackTrace) {
      _logger.e('Error en deleteProspect:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
