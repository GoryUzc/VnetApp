import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/widgets/admin_drawer.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        drawer: const CustomAdminDrawer(),
        body: _buildWelcomeContent(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text('Administrador'),
      backgroundColor: AppColors.primaryColor,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, color: Colors.white),
          tooltip: 'Mi cuenta',
          onSelected: (value) async {
            const storage = FlutterSecureStorage();
            final userId = await storage.read(key: 'user_id');
            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo obtener el usuario actual'),
                  ),
                );
              }
              return;
            }

            if (value == 'edit') {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserEditScreen(userId: userId),
                  ),
                );
              }
            } else if (value == 'delete') {
              if (!mounted) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Eliminar mi cuenta'),
                      content: const Text(
                        'Esta acción es irreversible. ¿Desea continuar?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
              if (!mounted) return;
              if (confirmed == true) {
                try {
                  await UserServices().deleteUser(userId);
                  await AuthService().logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const InitSelectUserScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            }
          },
          itemBuilder:
              (ctx) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar mi perfil')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar mi cuenta'),
                ),
              ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Desea cerrar la sesión actual?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Salir',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
            if (confirmed == true) {
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const InitSelectUserScreen(),
                  ),
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
      centerTitle: true,
      elevation: 4,
    );
  }

  Widget _buildWelcomeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 80, color: AppColors.primaryColor),
          const SizedBox(height: 20),
          const Text(
            "Bienvenido al Sistema VNET",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Gestión y Automatización de Instalaciones de Fibra Óptica",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
