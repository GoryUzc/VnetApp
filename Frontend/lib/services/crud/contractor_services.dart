// lib/services/admin/contractor_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/api_config.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:logger/logger.dart';

class ContractorService {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  /// Lista contratistas (admin/supervisores)
  Future<List<Map<String, dynamic>>> getAllContractors() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('contractors/list')),
        headers: headers,
      );

      _logger.d('GET /contractors/list -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['contractors'] is List)
                ? data['contractors'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 403) {
        throw Exception('Prohibido');
      } else {
        throw Exception('Error al obtener contratistas: ${response.body}');
      }
    } catch (e, st) {
      _logger.e('Error en getAllContractors', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Crear contratista (admin/supervisores)
  Future<Map<String, dynamic>> createContractor(
    Map<String, dynamic> contractorData,
  ) async {
    _logger.d('Creando nuevo contratista');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('contractors/create')),
        headers: headers,
        body: jsonEncode(contractorData),
      );

      _logger.d('POST /contractors/create -> ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final contractor =
            (data is Map<String, dynamic> && data['contractor'] is Map)
                ? Map<String, dynamic>.from(data['contractor'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Contratista creado exitosamente');
        return contractor;
      } else if (response.statusCode == 422 ||
          response.statusCode == 400 ||
          response.statusCode == 409) {
        throw Exception('Validación/Negocio: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 403) {
        throw Exception('Prohibido');
      } else {
        throw Exception('Error al crear contratista: ${response.body}');
      }
    } catch (e, st) {
      _logger.e('Error en createContractor', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Detalle de contratista
  Future<Map<String, dynamic>> getContractorDetails(String id) async {
    _logger.d('Obteniendo detalles del contratista: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('contractors/detail/$id')),
        headers: headers,
      );

      _logger.d('GET /contractors/detail/$id -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contractor =
            (data is Map<String, dynamic> && data['contractor'] is Map)
                ? Map<String, dynamic>.from(data['contractor'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Detalles del contratista obtenidos');
        return contractor;
      } else if (response.statusCode == 404) {
        throw Exception('Contratista no encontrado');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 403) {
        throw Exception('Prohibido');
      } else {
        throw Exception('Error al obtener detalles: ${response.body}');
      }
    } catch (e, st) {
      _logger.e('Error en getContractorDetails', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Mantener compatibilidad con el nombre previo mal escrito
  Future<Map<String, dynamic>> getContractrorDetails(String id) {
    return getContractorDetails(id);
  }

  /// Actualizar contratista
  Future<Map<String, dynamic>> updateContractor(
    String id,
    Map<String, dynamic> contractorData,
  ) async {
    _logger.d('Actualizando contratista: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('contractors/update/$id')),
        headers: headers,
        body: jsonEncode(contractorData),
      );

      _logger.d('PUT /contractors/update/$id -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contractor =
            (data is Map<String, dynamic> && data['contractor'] is Map)
                ? Map<String, dynamic>.from(data['contractor'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Contratista actualizado');
        return contractor;
      } else if (response.statusCode == 422 ||
          response.statusCode == 400 ||
          response.statusCode == 409) {
        throw Exception('Validación/Negocio: ${response.body}');
      } else if (response.statusCode == 404) {
        throw Exception('Contratista no encontrado');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 403) {
        throw Exception('Prohibido');
      } else {
        throw Exception('Error al actualizar contratista: ${response.body}');
      }
    } catch (e, st) {
      _logger.e('Error en updateContractor', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Eliminar contratista
  Future<void> deleteContractor(String id) async {
    _logger.d('Eliminando contratista: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.endpoint('contractors/delete/$id')),
        headers: headers,
      );

      _logger.d('DELETE /contractors/delete/$id -> ${response.statusCode}');

      if (response.statusCode == 200) {
        _logger.i('Contratista eliminado');
        return;
      } else if (response.statusCode == 400) {
        throw Exception('No se puede eliminar: ${response.body}');
      } else if (response.statusCode == 404) {
        throw Exception('Contratista no encontrado');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 403) {
        throw Exception('Prohibido');
      } else {
        throw Exception('Error al eliminar contratista: ${response.body}');
      }
    } catch (e, st) {
      _logger.e('Error en deleteContractor', error: e, stackTrace: st);
      rethrow;
    }
  }
}
