import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/widgets/admin_drawer.dart';
import 'package:vnet_agenda/screens/User/crud/prospects/prospect_list_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_list_screen.dart';
import 'package:vnet_agenda/screens/User/crud/contractors/contractor_list_screen.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeAdminScreen extends StatelessWidget {
  const HomeAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          "Panel de Administración",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Mi cuenta',
            onSelected: (value) async {
              const storage = FlutterSecureStorage();
              final userId = await storage.read(key: 'user_id');
              if (userId == null || userId.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo obtener el usuario actual'),
                    ),
                  );
                }
                return;
              }

              if (value == 'edit') {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserEditScreen(userId: userId),
                    ),
                  );
                }
              } else if (value == 'delete') {
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

                if (confirmed == true) {
                  try {
                    await UserServices().deleteUser(userId);
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const InitSelectUserScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
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
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const InitSelectUserScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
        centerTitle: true,
        elevation: 4,
      ),
      drawer: const AdminDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Bienvenido al Sistema",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Gestión y Automatización de Instalaciones",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildCard(
                    context,
                    'Prospectos',
                    'Gestiona los prospectos',
                    Icons.people_alt,
                    AppColors.primaryColor,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProspectListScreen(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    'Usuarios',
                    'Administra usuarios',
                    Icons.person,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserListScreen(),
                      ),
                    ),
                  ),
                  _buildCard(
                    context,
                    'Contratistas',
                    'Gestiona contratistas',
                    Icons.business,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContractorListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
