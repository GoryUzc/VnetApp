import 'package:flutter/material.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'User/login_user_screen.dart';
import 'clientes/login_clientes_screen.dart';

class InitSelectUserScreen extends StatelessWidget {
  const InitSelectUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Limitar el ancho máximo para pantallas web grandes
    final double maxWidth = screenWidth < 600 ? screenWidth : 600;
    final double buttonWidth = maxWidth * 0.8;
    final double verticalPadding = screenWidth * 0.05;

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
        elevation: 4,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: verticalPadding),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Image.asset(
                            "assets/images/image001.png",
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          AppStrings.systemDescription,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: buttonWidth,
                          child: Semantics(
                            label: AppStrings.vnetUsersSemantics,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const LoginUserScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                minimumSize: const Size(double.minPositive, 50),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                AppStrings.vnetUsers,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: buttonWidth,
                          child: Semantics(
                            label: AppStrings.clientsSemantics,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const LoginClienteScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                minimumSize: const Size(double.minPositive, 50),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                AppStrings.clients,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
