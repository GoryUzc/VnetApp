import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:http/http.dart' as http;

import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/services/api_config.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';

class OrderCreateScreen extends StatefulWidget {
  final String? prospectName; // opcional para mostrar contexto en el encabezado
  final String?
  technicianName; // opcional para mostrar contexto en el encabezado
  final String? meetingId; // opcional para mostrar contexto en el encabezado

  const OrderCreateScreen({
    super.key,
    this.prospectName,
    this.technicianName,
    this.meetingId,
  });

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Servicios
  final OrderService _orderService = OrderService();

  // Controllers de campos
  final TextEditingController _ontPuerto1Controller = TextEditingController();
  final TextEditingController _conectorScPCController = TextEditingController();
  final TextEditingController _patchCordScScaController =
      TextEditingController();
  final TextEditingController _rosetaController = TextEditingController();
  final TextEditingController _adapterScaController = TextEditingController();
  final TextEditingController _ont4PuertosController = TextEditingController();
  final TextEditingController _conectorScUpcController =
      TextEditingController();
  final TextEditingController _canaletasController = TextEditingController();
  final TextEditingController _ramplugController = TextEditingController();
  final TextEditingController _cableDropController = TextEditingController();
  final TextEditingController _hilosController = TextEditingController();
  final TextEditingController _potenciaRecibidaController =
      TextEditingController();
  final TextEditingController _macOntController = TextEditingController();
  final TextEditingController _serialOntController = TextEditingController();
  final TextEditingController _puertoNapController = TextEditingController();
  final TextEditingController _ppoeUserController = TextEditingController();
  final TextEditingController _ppoePasswordController = TextEditingController();
  final TextEditingController _ubicacionOnuController = TextEditingController();
  final TextEditingController _nroEquiposConectarController =
      TextEditingController();
  final TextEditingController _puertoOltController = TextEditingController();
  final TextEditingController _etiquetaClienteController =
      TextEditingController();
  final TextEditingController _routerController = TextEditingController();
  final TextEditingController _detallesInstalacionController =
      TextEditingController();

  // Firma
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  bool _isSigned = false;

  // Estado
  bool _loading = false;

  @override
  void dispose() {
    _ontPuerto1Controller.dispose();
    _conectorScPCController.dispose();
    _patchCordScScaController.dispose();
    _rosetaController.dispose();
    _adapterScaController.dispose();
    _ont4PuertosController.dispose();
    _conectorScUpcController.dispose();
    _canaletasController.dispose();
    _ramplugController.dispose();
    _cableDropController.dispose();
    _hilosController.dispose();
    _potenciaRecibidaController.dispose();
    _macOntController.dispose();
    _serialOntController.dispose();
    _puertoNapController.dispose();
    _ppoeUserController.dispose();
    _ppoePasswordController.dispose();
    _ubicacionOnuController.dispose();
    _nroEquiposConectarController.dispose();
    _puertoOltController.dispose();
    _etiquetaClienteController.dispose();
    _routerController.dispose();
    _detallesInstalacionController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _getSignatureBytes() async {
    if (!_isSigned) return null;
    final state = _signatureKey.currentState;
    if (state == null) return null;
    final image = await state.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _uploadSignature(String orderId) async {
    final bytes = await _getSignatureBytes();
    if (bytes == null) return; // nada que subir

    final token = await AuthService().getToken();
    final url = ApiConfig.endpoint('/orders/upload-signature/$orderId');

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(
      http.MultipartFile.fromBytes(
        'signature',
        bytes,
        filename: 'signature_$orderId.png',
      ),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al subir firma: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final data = {
        'ont_puerto_1': int.tryParse(_ontPuerto1Controller.text) ?? 0,
        'conector_sc_pc': int.tryParse(_conectorScPCController.text) ?? 0,
        'patch_cord_scpc-scapc':
            int.tryParse(_patchCordScScaController.text) ?? 0,
        'roseta': int.tryParse(_rosetaController.text) ?? 0,
        'adapter_scapc': int.tryParse(_adapterScaController.text) ?? 0,
        'ont_4_puertos': int.tryParse(_ont4PuertosController.text) ?? 0,
        'conector_sc_upc': int.tryParse(_conectorScUpcController.text) ?? 0,
        'canaletas': int.tryParse(_canaletasController.text) ?? 0,
        'ramplug': int.tryParse(_ramplugController.text) ?? 0,
        'cable_drop': int.tryParse(_cableDropController.text) ?? 0,
        'hilos': int.tryParse(_hilosController.text) ?? 0,
        'potencia_recibida_ont': _potenciaRecibidaController.text,
        'mac_ont': _macOntController.text,
        'serial_ont': _serialOntController.text,
        'puerto_nap': _puertoNapController.text,
        'ppoe_user': _ppoeUserController.text,
        'ppoe_password': _ppoePasswordController.text,
        'ubicacion_onu': _ubicacionOnuController.text,
        'nro_equipos_conectar': _nroEquiposConectarController.text,
        'puerto_olt': _puertoOltController.text,
        'etiqueta_cliente': _etiquetaClienteController.text,
        'router': _routerController.text,
        'detalles_instalacion': _detallesInstalacionController.text,
      };

      final created = await _orderService.createOrder(data);
      final orderId = (created['id'] ?? created['order_id'] ?? '').toString();
      if (orderId.isEmpty) {
        throw Exception('No se obtuvo el ID de la orden creada');
      }

      // Subir firma si está presente
      try {
        await _uploadSignature(orderId);
      } catch (e) {
        // No abortar la creación por fallo de firma, solo informar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Orden creada, pero la firma falló: $e')),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden creada correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Orden')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        _section(
                          'Datos de la orden: '
                          '${widget.prospectName ?? ''} '
                          '${widget.technicianName != null ? '- ${widget.technicianName}' : ''} '
                          '${widget.meetingId != null ? '- ${widget.meetingId}' : ''}',
                        ),
                        _textField(
                          controller: _ontPuerto1Controller,
                          label: 'ONT Puerto 1',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _conectorScPCController,
                          label: 'Conector SC PC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _patchCordScScaController,
                          label: 'Patch Cord SCPC-SCAPC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _rosetaController,
                          label: 'Roseta',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _adapterScaController,
                          label: 'Adapter SCAPC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _ont4PuertosController,
                          label: 'ONT 4 Puertos',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _conectorScUpcController,
                          label: 'Conector SC UPC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _canaletasController,
                          label: 'Canaletas',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _ramplugController,
                          label: 'Ramplug',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _cableDropController,
                          label: 'Cable Drop',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _hilosController,
                          label: 'Hilos',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                          required: true,
                        ),
                        _textField(
                          controller: _potenciaRecibidaController,
                          label: 'Potencia Recibida ONT',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _macOntController,
                          label: 'MAC ONT',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _serialOntController,
                          label: 'Serial ONT',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _puertoNapController,
                          label: 'Puerto NAP',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _ppoeUserController,
                          label: 'PPoE User',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _ppoePasswordController,
                          label: 'PPoE Password',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _ubicacionOnuController,
                          label: 'Ubicación ONU',
                          maxLen: 50,
                          required: true,
                        ),
                        _textField(
                          controller: _nroEquiposConectarController,
                          label: 'Nro Equipos a Conectar',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _puertoOltController,
                          label: 'Puerto OLT',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _etiquetaClienteController,
                          label: 'Etiqueta Cliente',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _routerController,
                          label: 'Router',
                          maxLen: 20,
                          required: true,
                        ),
                        _textField(
                          controller: _detallesInstalacionController,
                          label: 'Detalles Instalación',
                          maxLen: 200,
                          required: true,
                        ),

                        const SizedBox(height: 12),
                        _section('Firma del Cliente'),
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SfSignaturePad(
                            key: _signatureKey,
                            backgroundColor: Colors.white,
                            onDrawStart: () {
                              setState(() => _isSigned = true);
                              return true;
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  _isSigned
                                      ? () {
                                        _signatureKey.currentState?.clear();
                                        setState(() => _isSigned = false);
                                      }
                                      : null,
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpiar firma'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: const Icon(Icons.save),
                          label: const Text('Crear Orden'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool obscure = false,
    int? maxLen,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ).copyWith(labelText: label),
        obscureText: obscure,
        keyboardType: keyboard,
        maxLength: maxLen,
        validator:
            validator ??
            (v) {
              if (required && (v == null || v.isEmpty)) {
                return 'Campo requerido';
              }
              if (maxLen != null && v != null && v.length > maxLen) {
                return 'Máximo $maxLen caracteres';
              }
              return null;
            },
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}
