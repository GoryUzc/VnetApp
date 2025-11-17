import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/consult/aradial_api.dart';
import 'package:http/http.dart' as http; // ✅ FALTABA ESTE IMPORT

class AradialService {
  final Logger _logger = Logger();

  // Consulta de prospectos en aradial
  Future<Map<String, dynamic>> consultProspectAradial(String ci) async {
    _logger.d('Consultando cliente con cédula: $ci');

    try {
      // ✅ CORREGIDO: Usar try { } en lugar de try ( )
      final response = await http.get(
        Uri.parse(AradialApi.endpoint('/client/V/$ci')),
      );

      _logger.i('Respuesta recibida - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parsear respuesta exitosa
        final Map<String, dynamic> data = json.decode(response.body);
        _logger.d('Prospecto encontrado: $data');
        return data;
      } else {
        _logger.e('Error en la consulta - Status: ${response.statusCode}');
        throw Exception('Error al consultar prospecto: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error consultando prospecto con cédula $ci: $e');
      throw Exception('No se pudo consultar el prospecto: $e');
    }
  }
}
