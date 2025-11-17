import 'package:flutter/material.dart';
// import 'package:vnet_agenda/screens/clientes/select_contract_Screen.dart';
import 'package:vnet_agenda/screens/clientes/verify_otp_screen.dart';
import 'package:vnet_agenda/services/authentication/otp_service.dart';
// import 'package:vnet_agenda/services/consult/client_orchest_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';

class LoginClienteScreen extends StatefulWidget {
  const LoginClienteScreen({super.key});

  @override
  State<LoginClienteScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  // final ClientOrchestService _clientService = ClientOrchestService();
  final OtpService _otpService = OtpService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();

  bool _isLoading = false;
  String? _selectedTypeDocument = 'V';

  final List<Map<String, String>> _docTypes = [
    {'value': 'V', 'label': 'V - Venezolano'},
    {'value': 'E', 'label': 'E - Extranjero'},
    {'value': 'J', 'label': 'J - Jurídico'},
    {'value': 'G', 'label': 'G - Gobierno'},
    {'value': 'P', 'label': 'P - Pasaporte'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _processLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Formato: V25111111, E12345678, etc.
      // final String document = _documentController.text.trim();
      await _otpService.sendToOtp(
        _emailController.text.trim(),
        _documentController.text.trim(),
      );

      // PROCESAR LOGIN COMPLETO
      // final result = await _clientService.processClienteLogin(document);

      // if (result['success'] == true) {
      //   final clientData = result['client'];
      //   final clientExists = result['existsInLocal'];
      //   final contracts = result['contracts'];

      //   // Mostrar mensaje según si era nuevo o existente
      //   _showStatusMessage(clientExists, clientData['name']);

      // NAVEGAR A SELECCIÓN DE CONTRATO
      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(
        //   builder:
        //       (context) => SelectContractScreen(
        //         clientData: clientData,
        //         contracts: contracts,
        //         document: document,
        //       ),
        MaterialPageRoute(
          builder:
              (context) => VerifyOtpScreen(
                document: _documentController.text.trim(),
                email: _emailController.text.trim(),
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStatusMessage(bool clientExists, String clientName) {
    String message =
        clientExists
            ? '✅ Bienvenido de nuevo $clientName!'
            : '👋 ¡Bienvenido $clientName! (Cliente nuevo)';

    Color color = clientExists ? Colors.green : Colors.orange;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
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
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.emailRequired;
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
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
                      if (value.length < 6) return 'Mínimo 6 dígitos';
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
