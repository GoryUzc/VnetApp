import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/consult/aradial_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';

class ClientOrchestService {
  final Logger _logger = Logger();
  final AradialService _aradialService = AradialService();
  final ProspectService _prospectService = ProspectService();

  Future<Map<String, dynamic>> processClienteLogin(String document) async {
    _logger.d('Procesando login para : $document');

    try {
      // Consulta Api aradial
      final aradialData = await _aradialService.consultProspectAradial(
        document,
      );

      if (aradialData['satus'] != 'success') {
        throw Exception('Cliente no encontrado en aradial');
      }

      final clienteData = aradialData['data'];
      _logger.i('Datos obtenidos de Api: ${clienteData['name']}');

      // Extraer datos de la API
      _logger.i('Extrayendo datos de la API');
      final extractedData = _extractClientData(clienteData, document);

      // Verifica que el cliente exista en mi DB
      final localClient = await _prospectService.consultProspect(document);

      bool clientExists =
          localClient.containsKey('status') && localClient['status'] != null;

      if (!clientExists) {
        _logger.i('Cliente NO existe en mi DB');

        final backendData = _getDataForBackend(extractedData);
        await _prospectService.createProspect(backendData);
        _logger.i('Cliente creado');
      } else {
        _logger.i('Cliente ya existe en mi DB');
      }

      // Retorno de datos
      return {
        'success': true,
        'existsInLocal': clientExists,
        'contracts': extractedData['contracts'],
        'message':
            clientExists ? 'clientes existente' : 'cliente creado exitosamente',
      };
    } catch (e) {
      _logger.e('Error en processClientLogin: $e');
      rethrow;
    }
  }

  // EXTRAER DATOS DE LA API EXTERNA - MAPEADO PARA TU BACKEND
  Map<String, dynamic> _extractClientData(
    Map<String, dynamic> aradialData,
    String document,
  ) {
    try {
      // Extraer tipo de documento del string completo (Ej: "V25111111" -> "V")
      final docType = document.length > 1 ? document[0] : 'V';
      final docNumber = document.length > 1 ? document.substring(1) : document;

      // Extraer nombre y apellido
      final fullName = aradialData['name']?.toString() ?? '';
      final nameParts = fullName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Extraer contratos para la selección
      final List<Map<String, dynamic>> contracts = [];
      if (aradialData['contracts'] is List) {
        for (var contract in aradialData['contracts']) {
          // Extraer servicios del contrato
          final List<Map<String, dynamic>> services = [];
          if (contract['services'] is List) {
            for (var service in contract['services']) {
              services.add({
                'service_id': service['service_id']?.toString() ?? '',
                'service_name': service['service_name']?.toString() ?? '',
                'package_name': service['package_name']?.toString() ?? '',
                'price': service['price']?.toString() ?? '',
                'service_status': service['service_status']?.toString() ?? '',
              });
            }
          }

          contracts.add({
            'contract_id': contract['contract_id']?.toString() ?? '',
            'address': contract['address']?.toString() ?? '',
            'branch_office': contract['branch_office']?.toString() ?? '',
            'cellphone': contract['cellphone']?.toString() ?? '',
            'franchise_id': contract['franchise_id']?.toString() ?? '',
            'status': contract['status']?.toString() ?? '',
            'email': contract['email']?.toString() ?? '',
            'services': services,
          });
        }
      }

      // Obtener datos del primer contrato para información general
      final firstContract = contracts.isNotEmpty ? contracts[0] : {};
      final firstService =
          firstContract['services'] != null &&
                  firstContract['services'].isNotEmpty
              ? firstContract['services'][0]
              : {};

      // ✅ MAPEO CORRECTO PARA TU BACKEND LARAVEL
      return {
        // Campos REQUERIDOS por tu validación
        'aradial_id': aradialData['id']?.toString() ?? '',
        'name': firstName,
        'last_name': lastName,
        'document': docNumber, // Solo el número sin el tipo
        'document_type': docType, // 'V', 'E', 'J', etc.
        'phone': firstContract['cellphone']?.toString() ?? '',
        'address': firstContract['address']?.toString() ?? '',
        'city': aradialData['sucursal']?.toString() ?? '', // sucursal → city
        'email': aradialData['email']?.toString() ?? '',
        'plan': firstService['package_name']?.toString() ?? '',
        'franchise_id': firstContract['franchise_id']?.toString() ?? '',

        // Campos OPCIONALES por tu validación
        'status_red': '', // Puedes dejarlo vacío o asignar un valor por defecto
        // Campos adicionales para la app (no van al backend)
        'contracts': contracts,
        'full_name': fullName,
        'sucursal': aradialData['sucursal']?.toString() ?? '',
        'person_type': aradialData['person_type']?.toString() ?? '',
        'contracts_count': aradialData['contracts_count']?.toString() ?? '0',
        'source_system': 'aradial',
      };
    } catch (e) {
      _logger.e('❌ Error extrayendo datos: $e');

      // ✅ RETORNO MÍNIMO para evitar errores en el backend
      return {
        'aradial_id': aradialData['id']?.toString() ?? 'unknown',
        'name': aradialData['name']?.toString() ?? 'Cliente',
        'last_name': '',
        'document': document.length > 1 ? document.substring(1) : document,
        'document_type': document.length > 1 ? document[0] : 'V',
        'phone': '',
        'address': '',
        'city': aradialData['sucursal']?.toString() ?? '',
        'email': aradialData['email']?.toString() ?? '',
        'plan': '',
        'franchise_id': '',
        'status_red': '',
        'contracts': [],
        'error': e.toString(),
      };
    }
  }

  // MÉTODO PARA OBTENER SOLO LOS DATOS PARA EL BACKEND
  Map<String, dynamic> _getDataForBackend(Map<String, dynamic> fullData) {
    return {
      'aradial_id': fullData['aradial_id'],
      'name': fullData['name'],
      'last_name': fullData['last_name'],
      'document': fullData['document'],
      'document_type': fullData['document_type'],
      'phone': fullData['phone'],
      'address': fullData['address'],
      'city': fullData['city'],
      'email': fullData['email'],
      'plan': fullData['plan'],
      'franchise_id': fullData['franchise_id'],
      'status_red': fullData['status_red'] ?? '',
    };
  }
}
