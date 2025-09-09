import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/api_config.dart';

class FranchiseService {
  /// Obtiene todas las franquicias disponibles para mostrar en dropdowns
  Future<List<Map<String, dynamic>>> getAllFranchises() async {
    try {
      final uri = Uri.parse(ApiConfig.endpoint('franchises/list'));
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        final List<Map<String, dynamic>> dataList =
            (data['franchises'] as List)
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
          throw Exception(errorData['error'] ?? 'Error al obtener franquicias');
        } catch (_) {
          throw Exception(
            'Error al obtener franquicias (status ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      print('Error al obtener franquicias: $e');
      return [];
    }
  }
}
