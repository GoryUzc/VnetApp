import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/api_config.dart';

class UserServices {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  Future<List<Map<String, dynamic>>> getAllUser() async {
    _logger.d('Obteniendo lista de usuarios');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('users/list')),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista usuarios: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['users'] is List)
                ? data['users'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Usuarios obtenidos exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener usuarios: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getAllUser:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String id) async {
    _logger.d('Obteniendo detalles del usuario: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('users/detail/$id')),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user =
            (data is Map<String, dynamic> && data['user'] is Map)
                ? Map<String, dynamic>.from(data['user'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Detalles del usuario obtenidos exitosamente');
        return user;
      } else {
        throw Exception(
          'Error al obtener detalles del usuario: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getUserDetails:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    _logger.d('Creando nuevo usuario');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('users/create')),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user =
            (data is Map<String, dynamic> && data['user'] is Map)
                ? Map<String, dynamic>.from(data['user'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Usuario creado exitosamente');
        return user;
      } else if (response.statusCode == 422) {
        throw Exception('Validación: ${response.body}');
      } else {
        throw Exception('Error al crear usuario: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en createUser:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> userData,
  ) async {
    _logger.d('Actualizando usuario: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('users/update/$id')),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user =
            (data is Map<String, dynamic> && data['user'] is Map)
                ? Map<String, dynamic>.from(data['user'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Usuario actualizado exitosamente');
        return user;
      } else if (response.statusCode == 422) {
        throw Exception('Validación: ${response.body}');
      } else {
        throw Exception('Error al actualizar usuario: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en updateUser:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    _logger.d('Eliminando usuario: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.endpoint('users/delete/$id')),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar usuario: ${response.body}');
      }
      _logger.i('Usuario eliminado exitosamente');
    } catch (e, stackTrace) {
      _logger.e('Error en deleteUser:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
