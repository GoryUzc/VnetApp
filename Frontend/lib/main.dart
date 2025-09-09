import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema VNET',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const InitSelectUserScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
