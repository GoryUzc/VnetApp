import 'package:flutter/material.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import '../init_select_user_screen.dart';

class LoginClientesScreen extends StatelessWidget {
  const LoginClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Expanded(
          child: Text(
            "SISTEMA DE GESTION Y AUTOMATIZACION DE INSTALACIONES",
            style: TextStyle(
              fontStyle: FontStyle.normal,
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              alignment: const Alignment(0, 0),
              child: const Image(
                image: AssetImage("assets/images/image001.png"),
                width: 200,
                height: 200,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              alignment: const Alignment(20, 20),
              child: const TextField(
                decoration: InputDecoration(
                  labelText: 'ingrese su cedula de identidad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
                scrollPadding: EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InitSelectUserScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                minimumSize: const Size(200, 50),
                foregroundColor: Colors.white,
              ),
              child: const Text("Ingresar"),
            ),
          ],
        ),
      ),
    );
  }
}
