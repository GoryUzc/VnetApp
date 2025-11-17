import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:logger/logger.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class OrderService {
  Future<File> _savePdfBytes(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    _logger.d('Obteniendo las odenes de instalacion');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/orders/list')),
        headers: headers,
      );
      _logger.d('Codigo de estado : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Respuesta lista ordenes: $data');
        final List<dynamic> list =
            (data is Map<String, dynamic> && data['orders'] is List)
                ? data['orders'] as List
                : (data is List ? data : []);
        final result =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _logger.i('Ordenes obtenidas exitosamente: ${result.length}');
        return result;
      } else {
        throw Exception('Error al obtener ordenes: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getAllOrders:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(String id) async {
    _logger.d('Obteniendo detalles de la order: $id');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/orders/detail/$id')),
        headers: headers,
      );

      _logger.d('Código de estado: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final order =
            (data is Map<String, dynamic> && data['order'] is Map)
                ? Map<String, dynamic>.from(data['order'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Detalles de la orden obtenidos exitosamente');
        return order;
      } else {
        throw Exception(
          'Error al obtener detalles de la orden: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Error en getOrderDetails:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderByMeetingId(String meetingId) async {
    _logger.d('Obteniendo orden por ID de reunion: $meetingId');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/orders/user/installation/$meetingId')),
        headers: headers,
      );

      _logger.d('Codigo de respuesta: ${response.statusCode}');
      _logger.d('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final order =
            (data is Map<String, dynamic> && data['order'] is Map)
                ? Map<String, dynamic>.from(data['order'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Orden obtenida por meetingId exitosamente');
        return order;
      } else {
        throw Exception(
          'Error al obtener orden por meetingId: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error en getOrderByMeetingId:',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    _logger.d('Creando ordenes');

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('/orders/create')),
        headers: headers,
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final order =
            (data is Map<String, dynamic> && data['order'] is Map)
                ? Map<String, dynamic>.from(data['order'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Orden creado exitosamente');
        return order;
      } else if (response.statusCode == 422) {
        throw Exception('Validación: ${response.body}');
      } else {
        throw Exception('Error al crear orden: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en createOrder:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateOrder(
    String id,
    Map<String, dynamic> dataOrder,
  ) async {
    _logger.d('Actualizando orden');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.endpoint('orders/update/$id')),
        headers: headers,
        body: jsonEncode(dataOrder),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meeting =
            (data is Map<String, dynamic> && data['order'] is Map)
                ? Map<String, dynamic>.from(data['order'] as Map)
                : (data is Map<String, dynamic> ? data : <String, dynamic>{});
        _logger.i('Orden actualizado exitosamente');
        return meeting;
      } else if (response.statusCode == 422) {
        throw Exception('Validación: ${response.body}');
      } else {
        throw Exception('Error al actualizar orden: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en updateMeeting:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteOrder(String id) async {
    _logger.d('Eliminando orden: $id');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.endpoint('orders/delete/$id')),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar orden: ${response.body}');
      }
      _logger.i('Orden eliminado exitosamente');
    } catch (e, stackTrace) {
      _logger.e('Error en deleteOrder:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> pdfOrder(String id) async {
    _logger.d('Generando PDF para order: $id');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/orders/pdf/$id')),
        headers: {...headers, 'Accept': 'application/pdf'},
      );
      if (response.statusCode != 200) {
        throw Exception('Error al generar PDF de la orden: ${response.body}');
      }
      final Uint8List bytes = response.bodyBytes;
      final filename = 'orden_$id.pdf';
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..download = filename
              ..style.display = 'none';
        html.document.body!.children.add(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
        _logger.i('PDF descargado (web) para la orden: $id');
      } else {
        final file = await _savePdfBytes(bytes, filename);
        await OpenFilex.open(file.path);
        _logger.i('PDF guardado/abierto en móvil: ${file.path}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en pdfOrder:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> pdfOrderView(String id) async {
    _logger.d('Generando vista PDF para order: $id');
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/orders/pdf/preview/$id')),
        headers: {...headers, 'Accept': 'application/pdf'},
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Error al generar vista PDF de la orden: ${response.body}',
        );
      }
      final Uint8List bytes = response.bodyBytes;
      final filename = 'orden_$id.pdf';
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        _logger.i('Previsualización abierta (web) para la orden: $id');
      } else {
        final file = await _savePdfBytes(bytes, filename);
        await OpenFilex.open(file.path);
        _logger.i('Previsualización en móvil: ${file.path}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error en pdfOrderView:', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  
}
