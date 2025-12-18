import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/screens/User/admin/home_admin_screen.dart';
import 'package:vnet_agenda/screens/User/supervisor/home_supervisor_screen.dart';
import 'package:vnet_agenda/screens/User/contractor/home_contractor_screen.dart';
import 'package:vnet_agenda/screens/User/worker/home_worker_screen.dart';
import 'package:vnet_agenda/screens/register_user_screen.dart';

class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({super.key});

  @override
  State<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Obtener los datos completos del login
      final loginData = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Obtener el role_id del usuario
      final role = loginData['role_id'];
      //final franchise = loginData['franchise_id'];

      // Redirigir según el role_id
      if (role == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeAdminScreen()),
        );
      } else if (role == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeSupervisorScreen()),
        );
      } else if (role == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeContractorScreen()),
        );
      } else if (role == 4) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeWorkerScreen()),
        );
      } else {
        // Para roles desconocidos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rol no reconocido, contacte al administrador'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.passwordRequired;
                      }
                      if (value.length < 8) {
                        return AppStrings.passwordTooShort;
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
                          onPressed: _isLoading ? null : _login,
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
                  // const SizedBox(height: 12),
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => const RegisterUserScreen(),
                  //       ),
                  //     );
                  //   },
                  //   child: const Text(
                  //     'Crear cuenta',
                  //     style: TextStyle(decoration: TextDecoration.underline),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
