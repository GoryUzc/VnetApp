import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_completion_screen.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_signature_screen.dart';
import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';

class OrderEditScreen extends StatefulWidget {
  final String orderId;
  final String prospectId;
  final String userId;
  final String meetingId;
  const OrderEditScreen({
    super.key,
    required this.orderId,
    required this.prospectId,
    required this.userId,
    required this.meetingId,
  });

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  final _formatKey = GlobalKey<FormState>();
  final Logger _logger = Logger();
  //Servicios
  final UserServices _userServices = UserServices();
  final ProspectService _prospectService = ProspectService();
  final OrderService _orderService = OrderService();

  // COntrollers

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

  // Catalogo y nombres de Prospecto y tecnico
  List<Map<String, dynamic>> _prospects = [];
  List<Map<String, dynamic>> _users = [];
  String _prospect(String? id) {
    try {
      return _prospects.firstWhere(
        (element) => element['id'].toString() == id,
      )['name'];
    } catch (e) {
      return '';
    }
  }

  String _user(String? id) {
    try {
      return _users.firstWhere(
        (element) => element['id'].toString() == id,
      )['name'];
    } catch (e) {
      return '';
    }
  }

  String _roleId(String? id) {
    try {
      return _users
          .firstWhere((element) => element['id'].toString() == id)['role_id']
          .toString();
    } catch (e) {
      return '';
    }
  }

  // Estado
  bool _loading = true;
  String? _error = '';

  @override
  void initState() {
    super.initState();
    _initLoad();
    }

  Future<void> _initLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([_loadProspects(), _loadUsers(), _loadOrders()]);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProspects() async {
    try {
      final data = await _prospectService.getAllProspects();
      setState(() {
        _prospects = data;
      });
    } catch (_) {
      // Ya se notifica UI si falla general
    } finally {
      // _loading se maneja en _initLoad
    }
  }

  Future<void> _loadUsers() async {
    try {
      final data = await _userServices.getAllUser();
      setState(() {
        _users = data;
      });
    } catch (_) {
      // Ya se notifica UI si falla general
    } finally {
      // _loading se maneja en _initLoad
    }
  }

  Future<void> _loadOrders() async {
    final u = await _orderService.getOrderDetails(widget.orderId);

    // Setear controllers
    _ontPuerto1Controller.text = (u['ont_puerto_1'] ?? '').toString();
    _conectorScPCController.text = (u['conector_sc_pc'] ?? '').toString();
    _patchCordScScaController.text =
        (u['patch_cord_scpc-scapc'] ?? '').toString();
    _rosetaController.text = (u['roseta'] ?? '').toString();
    _adapterScaController.text = (u['adapter_scapc'] ?? '').toString();
    _ont4PuertosController.text = (u['ont_4_puertos'] ?? '').toString();
    _conectorScUpcController.text = (u['conector_sc_upc'] ?? '').toString();
    _canaletasController.text = (u['canaletas'] ?? '').toString();
    _ramplugController.text = (u['ramplug'] ?? '').toString();
    _cableDropController.text = (u['cable_drop'] ?? '').toString();
    _hilosController.text = (u['hilos'] ?? '').toString();
    _potenciaRecibidaController.text =
        (u['potencia_recibida_ont'] ?? '').toString();
    _macOntController.text = (u['mac_ont'] ?? '').toString();
    _serialOntController.text = (u['serial_ont'] ?? '').toString();
    _puertoNapController.text = (u['puerto_nap'] ?? '').toString();
    _ppoeUserController.text = (u['ppoe_user'] ?? '').toString();
    _ppoePasswordController.text = (u['ppoe_password'] ?? '').toString();
    _ubicacionOnuController.text = (u['ubicacion_onu'] ?? '').toString();
    _nroEquiposConectarController.text =
        (u['nro_equipos_conectar'] ?? '').toString();
    _puertoOltController.text = (u['puerto_olt'] ?? '').toString();
    _etiquetaClienteController.text = (u['etiqueta_cliente'] ?? '').toString();
    _routerController.text = (u['router'] ?? '').toString();
    _detallesInstalacionController.text =
        (u['detalles_instalacion'] ?? '').toString();

    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formatKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
      // Actualizar
      await _orderService.updateOrder(widget.orderId, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orden actualizada'),
          backgroundColor: Colors.green,
        ),
      );
      // Navega a la pantalla de firma y espera a que finalice
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignatureScreen(orderId: widget.orderId, meetingId: widget.meetingId,),
        ),
      );
      if (!mounted) return;
      // Al finalizar la firma, llevar a pantalla de cierre
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderCompletionScreen(orderId: widget.orderId),
        ),
      );
          // No hacer pop automáticamente aquí para no interferir con el flujo de firma
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
      appBar: AppBar(title: const Text('Editar Orden')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorView(message: _error!, onRetry: _initLoad)
              : SafeArea(
                child: Form(
                  key: _formatKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        _section(
                          'Datos de la orden: '
                          '${_prospect(widget.prospectId)} - '
                          '${_user(widget.userId)} - '
                          '${widget.meetingId}',
                        ),
                        _textField(
                          controller: _ontPuerto1Controller,
                          label: 'ONT Puerto 1',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _conectorScPCController,
                          label: 'Conector SC PC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _patchCordScScaController,
                          label: 'Patch Cord SCPC-SCAPC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _rosetaController,
                          label: 'Roseta',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _adapterScaController,
                          label: 'Adapter SCAPC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _ont4PuertosController,
                          label: 'ONT 4 Puertos',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _conectorScUpcController,
                          label: 'Conector SC UPC',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _canaletasController,
                          label: 'Canaletas',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _ramplugController,
                          label: 'Ramplug',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _cableDropController,
                          label: 'Cable Drop',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _hilosController,
                          label: 'Hilos',
                          keyboard: TextInputType.number,
                          maxLen: 5,
                        ),
                        _textField(
                          controller: _potenciaRecibidaController,
                          label: 'Potencia Recibida ONT',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _macOntController,
                          label: 'MAC ONT',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _serialOntController,
                          label: 'Serial ONT',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _puertoNapController,
                          label: 'Puerto NAP',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _ppoeUserController,
                          label: 'PPoE User',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _ppoePasswordController,
                          label: 'PPoE Password',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _ubicacionOnuController,
                          label: 'Ubicación ONU',
                          maxLen: 50,
                        ),
                        _textField(
                          controller: _nroEquiposConectarController,
                          label: 'Nro Equipos a Conectar',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _puertoOltController,
                          label: 'Puerto OLT',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _etiquetaClienteController,
                          label: 'Etiqueta Cliente',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _routerController,
                          label: 'Router',
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _detallesInstalacionController,
                          label: 'Detalles Instalación',
                          maxLen: 200,
                        ),
                        const SizedBox(height: 20),

                        // Botones según rol del usuario
                        Builder(
                          builder: (context) {
                            final role = _roleId(widget.userId);
                            if (role == '3') {
                              return FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.pages),
                                label: const Text('Verificar orden y firmar'),
                              );
                            } else if (role == '4') {
                              return FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar Cambios'),
                              );
                            }
                            // Rol por defecto: mostrar guardar
                            return FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar Cambios'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

                // 'ont_puerto_1' =>'required|numeric|min:0',
                // 'conector_sc_pc'=>'required|numeric|min:0',
                // 'patch_cord_scpc-scapc'=>'required|numeric|min:0',
                // 'roseta'=>'required|numeric|min:0',
                // 'adapter_scapc'=>'required|numeric|min:0',
                // 'ont_4_puertos'=>'required|numeric|min:0',
                // 'conector_sc_upc'=>'required|numeric|min:0',
                // 'canaletas'=>'required|numeric|min:0',
                // 'ramplug'=>'required|numeric|min:0',
                // 'cable_drop'=>'required|numeric|min:0',
                // 'hilos'=>'required|numeric|min:0',
                // 'potencia_recibida_ont'=>'required|string',
                // 'mac_ont'=>'required|string',
                // 'serial_ont'=>'required|string',
                // 'puerto_nap'=>'required|string',
                // 'ppoe_user'=>'required|string',
                // 'ppoe_password'=>'required|string',
                // 'ubicacion_onu'=>'required|string',
                // 'nro_equipos_conectar'=>'required|string',
                // 'puerto_olt'=>'required|string',
                // 'etiqueta_cliente'=>'required|string',
                // 'router'=>'required|string',
                // 'detalles_instalacion'=>'required|string',