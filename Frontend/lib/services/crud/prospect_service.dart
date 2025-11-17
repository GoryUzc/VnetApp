import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:logger/logger.dart';

class ProspectService {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  String _parseValidationErrors(String responseBody) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(responseBody);

      // Laravel devuelve errores de validación en diferentes formatos
      if (errorData.containsKey('errors')) {
        // Formato estándar de Laravel: {"errors": {"campo": ["mensaje1", "mensaje2"]}}
        final Map<String, dynamic> errors = errorData['errors'];
        final errorMessages = <String>[];

        errors.forEach((field, messages) {
          if (messages is List) {
            for (final message in messages) {
              errorMessages.add('$field: $message');
            }
          } else if (messages is String) {
            errorMessages.add('$field: $messages');
          }
        });

        return errorMessages.join(', ');
      } else if (errorData.containsKey('message')) {
        // Formato simple: {"message": "Error de validación"}
        return errorData['message'].toString();
      } else {
        // Si no reconocemos el formato, devolver el cuerpo original
        _logger.w('Formato de error no reconocido: $errorData');
        return 'Error de validación: ${errorData.toString()}';
      }
    } catch (e) {
      _logger.e('Error parseando errores de validación: $e');
      // Si no podemos parsear JSON, devolver el texto original
      return responseBody;
    }
  }

  Future<List<Map<String, dynamic>>> getAllProspects() async {
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
        _logger.d('Datos $data');
        //Manejo de diferentes tipos de respuesta
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['prospects'] is List)
                ? data['prospects'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Prospectos obtenidos exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener Prospectos: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getAllProspect:', error: e, stackTrace: stackTrace);
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
      } else if (response.statusCode == 204) {
        _logger.i('No hay contenido para el prospecto solicitado');
        return {};
      } else if (response.statusCode == 404) {
        throw Exception('Prospecto no encontrado');
      } else if (response.statusCode == 401) {
        throw Exception('Sesion expirada. Por favor inicie sesion nuevamente');
      } else if (response.statusCode == 403) {
        throw Exception('El usuario no tiene permisos para esta funcion');
      } else {
        throw Exception('Error al obtener detalles: ${response.body}');
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

      // CORREGIDO: Verificar tanto 200 como 201 como respuestas exitosas
      if (response.statusCode == 200 || response.statusCode == 201) {
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

  Future<Map<String, dynamic>> consultProspect(String id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('prospect/consult/{$id}')),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'message': data['status']};
      } else if (response.statusCode == 404) {
        return {'message': data['error']};
      } else {
        return {};
      }
    } catch (e, stackTrace) {
      _logger.e('Error en consultProspect:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
