import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/api_config.dart';

class RoleService {

  
final Logger _logger = Logger();

  /// Obtiene todas loss roles disponibles para mostrar en dropdowns
  Future<List<Map<String, dynamic>>> getAllRole() async {
    try {
      final uri = Uri.parse(ApiConfig.endpoint('roles/list'));
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        final List<Map<String, dynamic>> dataList =
            (data['roles'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
        return dataList;
      } else if (response.statusCode == 204) {
        // Sin contenido
        return [];
      } else {
        // Errores específicos del backend
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Error al obtener roles');
        } catch (_) {
          throw Exception(
            'Error al obtener roles (status ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      _logger.e('Error al obtener roles: $e');
      return [];
    }
  }
}
