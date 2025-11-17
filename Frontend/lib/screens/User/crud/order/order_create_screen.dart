import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_signature_screen.dart';
import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/strings/app_strings.dart';

class OrderCreateScreen extends StatefulWidget {
  final String? prospectName; // opcional para mostrar contexto en el encabezado
  final String? meetingId;
  final String? userId; // opcional para mostrar contexto en el encabezado
  final String? prospectId; // opcional para mostrar contexto en el encabezado

  const OrderCreateScreen({
    super.key,
    this.prospectName,
    this.meetingId,
    this.prospectId,
    this.userId,
  });

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final Logger _logger = Logger();

  // Servicios
  final OrderService _orderService = OrderService();

  // Variables
  String idMeeting = '';
  String userId = '';
  String prospectId = '';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    userId = id(widget.userId);
    idMeeting = id(widget.meetingId);
    prospectId = id(widget.prospectId);

    setState(() => _loading = true);
    try {
      final data = {
        'user_id': userId,
        'id_meeting': idMeeting,
        'prospect_aradial_id': prospectId,
        'ont_puerto_1': int.tryParse(_ontPuerto1Controller.text) ?? 0,
        'conector_sc_pc': int.tryParse(_conectorScPCController.text) ?? 0,
        'patch_cord_scsp_scapc':
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
      final orderId = created['id']?.toString();
      if (orderId == null || orderId.isEmpty) {
        throw Exception('No se recibió el ID de la orden desde el servidor');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden creada correctamente')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => SignatureScreen(orderId: orderId, meetingId: idMeeting),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String id(dynamic data) {
    final idM = data.toString();
    _logger.d('El ID de la Cita: $idM');
    return idM.isNotEmpty ? idM : AppStrings.anonymous;
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
                        _section('Datos de la orden de instalacion: '),
                        _section(
                          'Cliente : '
                          '${widget.prospectName ?? ''} '
                          'Numero de orden: '
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

                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: const Icon(Icons.save),
                          label: const Text('Verificacion instalacion'),
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
