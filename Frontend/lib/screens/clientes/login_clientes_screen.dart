import 'package:flutter/material.dart';
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
  final OtpService _authService = OtpService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Obtener los datos completos del login
      final loginData = await _authService.sendToOtp(
        _emailController.text.trim(),
        _documentController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => VerifyOtpScreen(
                email: _emailController.text.trim(),
                document: _documentController.text.trim(),
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          AppStrings.appTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    fit: BoxFit.contain,
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
                  TextFormField(
                    controller: _documentController,
                    decoration: InputDecoration(
                      labelText: 'Documento de identidad', // Cambia el label
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _sendOtp(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El documento es requerido';
                      }
                      if (value.length < 6) {
                        return 'El documento debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            AppStrings.login,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
