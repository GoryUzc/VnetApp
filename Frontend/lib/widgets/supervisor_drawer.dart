import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/list_meeting_assigned_screen.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/list_meeting_screen.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/list_meeting_unassegned_screen.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_list_screen.dart';
import 'package:vnet_agenda/screens/User/crud/prospects/prospect_list_screen.dart';
import 'package:vnet_agenda/screens/User/crud/contractors/contractor_list_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class CustomSupervisorDrawer extends StatelessWidget {
  const CustomSupervisorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del Drawer
          _buildHeader(),

          // Lista de navegación
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Sección: Gestión de Citas
                _buildSectionHeader('📅 Gestión de Citas'),
                _buildDrawerItem(
                  context,
                  'Todas las Citas',
                  Icons.list,
                  () => _navigateTo(context, const MeetingListScreen()),
                ),
                _buildDrawerItem(
                  context,
                  'Citas Asignadas',
                  Icons.assignment_turned_in,
                  () => _navigateTo(context, const MeetingAssignedListScreen()),
                ),
                _buildDrawerItem(
                  context,
                  'Citas sin Asignar',
                  Icons.assignment_late,
                  () =>
                      _navigateTo(context, const MeetingUnassignedListScreen()),
                ),

                const Divider(),

                _buildDrawerItem(
                  context,
                  'Contratistas',
                  Icons.business,
                  () => _navigateTo(context, const ContractorListScreen()),
                ),
                _buildDrawerItem(
                  context,
                  'Prospectos/Clientes',
                  Icons.people_alt,
                  () => _navigateTo(context, const ProspectListScreen()),
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
                const Divider(),

                // Sección: Reportes y Estadísticas
                _buildSectionHeader('📊 Reportes y Análisis'),
                _buildDrawerItem(
                  context,
                  'Estadísticas Generales',
                  Icons.analytics,
                  () => _showComingSoon(context),
                ),

                const Divider(),

                // Sección: Configuración
                _buildSectionHeader('⚙️ Configuración'),
                _buildDrawerItem(
                  context,
                  'Configuración del Sistema',
                  Icons.settings,
                  () => _showComingSoon(context),
                ),
                _buildDrawerItem(
                  context,
                  'Ayuda y Soporte',
                  Icons.help,
                  () => _showComingSoon(context),
                ),
              ],
            ),
          ),

          // Footer del Drawer
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            'Panel de Supervisor',
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
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 14,
        ),
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

  void _showComingSoon(BuildContext context) {
    Navigator.pop(context); // Cerrar el drawer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo - Próximamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
