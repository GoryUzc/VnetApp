import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/api_config.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';

class ContractorService {
  final AuthService _authService = AuthService();

  /// Obtiene todos los contratistas (requiere autorización)
  Future<List<Map<String, dynamic>>> getAllContractor() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final uri = Uri.parse(ApiConfig.endpoint('contractor/list'));
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawList =
            (decoded is Map<String, dynamic> && decoded['contractors'] is List)
                ? decoded['contractors'] as List
                : (decoded is List ? decoded : []);
        final List<Map<String, dynamic>> dataList =
            rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return dataList;
      } else if (response.statusCode == 204) {
        // Sin contenido
        return [];
      } else {
        // Errores específicos del backend
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
            errorData['message'] ??
                errorData['error'] ??
                'Error al obtener contratistas',
          );
        } catch (_) {
          throw Exception(
            'Error al obtener contratistas (status ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      // Mantener el comportamiento no disruptivo en capa others
      // (retornar lista vacía en caso de error)
      // Si requieres diagnosticar, cambia a: rethrow;
      // print('Error al obtener contratistas: $e');
      return [];
    }
  }
}
