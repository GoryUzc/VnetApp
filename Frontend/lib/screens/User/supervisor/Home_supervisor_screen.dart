import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';
import 'package:vnet_agenda/widgets/supervisor_drawer.dart';

class HomeSupervisorScreen extends StatefulWidget {
  const HomeSupervisorScreen({super.key});

  @override
  State<HomeSupervisorScreen> createState() => _HomeSupervisorScreenState();
}

Logger _logger = Logger();

class _HomeSupervisorScreenState extends State<HomeSupervisorScreen> {
  final ProspectService _prospectService = ProspectService();
  final MeetingService _meetingService = MeetingService();
  List<Map<String, dynamic>> _meetings = [];
  bool _loading = false;
  String _errorMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _loading = true;
        _errorMessage = ' ';
        _hasError = false;
      });

      try {
        final data = await _meetingService.getAllMeetingEnd();
        _logger.d('Data de las citas finalizadas: $data');
        _meetings = data;

        if (mounted) {
          setState(() {
            _meetings = data;
            _loading = false;
          });
        }
      } catch (e) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
        _showErrorSnackBar(e);
      }
    }
  }

  void _showErrorSnackBar(dynamic error) {
    String message;

    if (error.toString().contains('Network')) {
      message = AppStrings.networkError;
    } else if (error.toString().contains('401')) {
      message = AppStrings.unauthorizedError;
    } else if (error.toString().contains('404')) {
      message = AppStrings.notFoundError;
    } else {
      message = AppStrings.genericError;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Recargar',
          textColor: Colors.white,
          onPressed: () {
            _load(isRefreshing: true);
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _statusChange(String id) {
    _logger.d('Activando al cliente $id');
  }

  Widget _buildTable() {
    return RefreshIndicator(
      semanticsLabel: 'Activacion Internet cliente',
      onRefresh: () => _load(isRefreshing: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.00),
        child: DataTableCustom(
          columns: const [
            'nro_contract',
            'tecnico',
            'contratista',
            'status',
            'usuario_ppoe',
            'password_ppoe',
            // 'id_cita'
          ],
          rows:
              _meetings.map((meeting) {
                return {
                  'nro_contract': meeting['nro_contract'] ?? '',
                  'tecnico': meeting['tecnico'] ?? '',
                  'contratista': meeting['contratista'] ?? '',
                  'status': meeting['status'] ?? '',
                  'usuario_ppoe': meeting['usuario_ppoe'] ?? '',
                  'password_ppoe': meeting['password_ppoe'] ?? '',
                  'id_cita': meeting['id_cita'] ?? '',
                };
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Panel de Supervisor',
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
                if (context.mounted) {
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
      ),
      drawer: const CustomSupervisorDrawer(),
      body: _buildWelcomeContent(),
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
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
