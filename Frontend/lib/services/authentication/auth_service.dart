import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _logger = Logger();

  /// Inicia sesión y devuelve los datos del usuario
  Future<Map<String, dynamic>> login(String email, String password) async {
    _logger.d('Intentando login para: $email');
    _logger.d('URL de login: ${ApiConfig.endpoint('login')}'); // ApiConfig

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('login')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // _logger.d('Código de estado: ${response.statusCode}');
      // _logger.d('Headers de respuesta: ${response.headers}');
      // _logger.d('Longitud del cuerpo: ${response.body.length}');
      // _logger.d(
      //   'Primeros 100 caracteres del cuerpo: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}',
      // );

      if (response.body.isEmpty) {
        throw Exception(
          'Respuesta del servidor vacía. Verifica el endpoint y CORS',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Estructura completa de la respuesta del login: $data');

        // Guardar token y datos del usuario
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(
          key: 'user_id',
          value: data['id']?.toString() ?? '',
        );
        await _storage.write(
          key: 'role_id',
          value: data['role_id']?.toString() ?? '',
        );
        await _storage.write(
          key: 'franchise_id',
          value: data['franchise_id']?.toString() ?? '',
        );

        _logger.i('Login exitoso, token almacenado');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error de autenticación');
      }
    } catch (e, stackTrace) {
      _logger.e('Error de login:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Método para obtener el role_id
  Future<String> getUserRole() async {
    final roleStr = await _storage.read(key: 'role_id');
    return roleStr ?? '';
  }

  Future<int> getUserfranchise() async {
    final franchiseStr = await _storage.read(key: 'franchise_id');
    _logger.d('franchise_id from storage: $franchiseStr');
    return franchiseStr != null ? int.parse(franchiseStr) : 0;
  }

  /// Obtiene el token JWT almacenado
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> getUserId() async {
    final userId = await _storage.read(key: 'user_id');
    return userId ?? '';
  }

  /// Obtiene los headers de autenticación
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String? useId;
  String? franchiseId;
  Future<Map<String, dynamic>> getDataUserRoleFranchise() async {
    final userId = await _storage.read(key: 'role_id');
    final franchiseId = await _storage.read(key: 'franchise_id');
    return {'role': userId, 'franchise': franchiseId};
  }

  /// Cierra sesión eliminando el token
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  /// Verifica si el usuario está autenticado
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
