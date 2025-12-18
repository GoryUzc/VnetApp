import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/clientes/verify_otp_screen.dart';
import 'package:vnet_agenda/services/authentication/otp_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';

class LoginClienteScreen extends StatefulWidget {
  const LoginClienteScreen({super.key});

  @override
  State<LoginClienteScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final OtpService _otpService = OtpService();
  final TextEditingController _documentController = TextEditingController();
  final Logger _logger = Logger();

  bool _isLoading = false;
  String? _selectedTypeDocument;
  String _email = '';
  String _clienteId = '';

  final List<Map<String, String>> _docTypes = [
    {'value': 'V', 'label': 'V - Venezolano'},
    {'value': 'E', 'label': 'E - Extranjero'},
    {'value': 'J', 'label': 'J - Jurídico'},
    {'value': 'G', 'label': 'G - Gobierno'},
    {'value': 'P', 'label': 'P - Pasaporte'},
  ];

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }

  void showStatusMessage(bool clientExists, String clientId) {
    String message = clientExists ? '✅ Bienvenido!' : '👋 ¡Bienvenido!';

    Color color = clientExists ? Colors.green : Colors.orange;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _processLogin() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos correctamente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String document = _documentController.text.trim();
      final result = await _otpService.getConsultClient(
        document,
        _selectedTypeDocument ?? 'V',
      );

      _logger.d('📥 Resultado completo: $result');

      if (result['status'] == 'success') {
        final int clientId = result['prospect'] ?? 0;
        final bool clientExists = result['existInAradial'] == true;
        final String emailProspect = result['email'] ?? '';
        // ✅ USAR contract_ids EN LUGAR DE contracts
        final List<dynamic> contractIds = result['contract_ids'] ?? [];

        // ✅ EXTRAER EMAIL Y NOMBRE
        _email = emailProspect;
        _clienteId = clientId.toString();

        _logger.d('   - Email: $_email');
        _logger.d('   - Email: $_clienteId');
        _logger.d('   - Existe en Aradial: $clientExists');
        _logger.d('   - Contract IDs: $contractIds');

        // Mostrar mensaje según si era nuevo o existente
        showStatusMessage(clientExists, _clienteId);

        final sendOtp = await _otpService.sendToOtp(_email, document);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => VerifyOtpScreen(
                  document: document,
                  email: _email,
                  contractIds: contractIds, // ✅ Ahora usamos contract_ids
                  clienteId: _clienteId,
                ),
          ),
        );
      } else {
        // ✅ MANEJO DE ERRORES
        final errorMessage = result['message'] ?? 'Error desconocido';
        _logger.e('❌ Error en la API: $errorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, st) {
      _logger.e('💥 Error en _processLogin: $e', error: e, stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(AppStrings.appTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    "assets/images/image001.png",
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppStrings.welcomeMessage,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // SELECTOR TIPO DOCUMENTO
                  DropdownButtonFormField<String>(
                    value: _selectedTypeDocument,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Documento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    items:
                        _docTypes.map((docType) {
                          return DropdownMenuItem<String>(
                            value: docType['value'],
                            child: Text(docType['label']!),
                          );
                        }).toList(),
                    onChanged:
                        (value) =>
                            setState(() => _selectedTypeDocument = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleccione un tipo de documento';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // CAMPO DOCUMENTO
                  TextFormField(
                    controller: _documentController,
                    decoration: InputDecoration(
                      labelText: 'Número de Documento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.credit_card),
                      hintText: 'Ej: 25111111',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El documento es requerido';
                      }
                      if (value.length < 8) return 'Mínimo 8 dígitos';
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // BOTÓN DE LOGIN
                  _isLoading
                      ? const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Verificando documento...'),
                        ],
                      )
                      : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _processLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continuar',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
