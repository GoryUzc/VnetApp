import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/list_meeting_unassegned_screen.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_list_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class CustomWorkerDrawer extends StatelessWidget {
  final userId;
  const CustomWorkerDrawer({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          _buildHeader(),

          // Lista de navegacion
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Seccion: Gestion de citas
                _buildSectionHeader('📅 Gestión de Citas'),
                _buildDrawerItem(
                  context,
                  'Citas Disponibles',
                  Icons.list,
                  () => _navigateTo(
                    context,
                    MeetingUnassignedListScreen(userId: userId),
                  ),
                ),

                const Divider(),

                // Seccion: Gestion de ordenes de instalacion
                _buildSectionHeader('🛠️ Gestión de Órdenes de Instalación'),
                _buildDrawerItem(
                  context,
                  'Ordenes de instalacion completadas',
                  Icons.pageview,
                  () => _navigateTo(context, const OrderListScreen()),
                ),
              ],
            ),
          ),

          // Footer del drawer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business,
              size: 40,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'VNET AGENDA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Panel Trabajador de Contratista',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Text(
            'v1.0.0',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Sistema de Gestión VNET',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Cerrar el drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
