import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Inicializar el formato de fechas en español
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Agenda VNET',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const InitSelectUserScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
