import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';
import 'package:vnet_agenda/widgets/worker_drawer.dart';

class HomeWorkerScreen extends StatefulWidget {
  HomeWorkerScreen({super.key});
 
  @override
  State<HomeWorkerScreen> createState() => _HomeWorkerScreenState();
}

class _HomeWorkerScreenState extends State<HomeWorkerScreen> {
  final ProspectService _prospectService = ProspectService();
  final MeetingService _meetingService = MeetingService();
  final Logger _logger = Logger();
  final Map<String, Map<String, dynamic>> _prospects = {};
  List<Map<String, dynamic>> _meetings = [];
  String? id;
  bool _loading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });
    }
    try {
      final data = await _meetingService.getAllMeetingUser();
      _meetings = data;

      final prospectIds =
          _meetings
              .map((m) => m['prospect_aradial_id']?.toString())
              .where((id) => id != null && id!.isNotEmpty)
              .cast<String>()
              .toSet();

      final futures = <Future<void>>[];
      for (final pid in prospectIds) {
        if (!_prospects.containsKey(pid)) {
          futures.add(
            _prospectService
                .getProspectDetails(pid)
                .then((pData) {
                  // Asegurar que sea un Map<String, dynamic>
                  final map = Map<String, dynamic>.from(pData);
                  _logger.d('1 $map');
                  _prospects[pid] = map['prospect'];
                  _logger.d('2 $_prospects');
                })
                .catchError((e) {
                  _logger.w('No se pudo cargar prospecto $pid: $e');
                  _prospects[pid] = {};
                  _logger.d('Los prospects $_prospects');
                }),
          );
        }
      }
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatProspectName(Map<String, dynamic>? p) {
    if (p == null) return AppStrings.anonymous;
    final first = p['name']?.toString() ?? '';
    final last = p['last_name']?.toString() ?? '';
    final full = (first + ' ' + last).trim();
    return full.isNotEmpty ? full : AppStrings.anonymous;
  }

  Widget _buildTable() {
    return RefreshIndicator(
      semanticsLabel: 'Mis Citas de Instalacion',
      onRefresh: () => _load(isRefreshing: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: DataTableCustom(
                columns: const [
                  'Cliente',
                  'plan',
                  'Fecha y Hora',
                  'telefono',
                  'Dirección',
                ],
                rows:
                    _meetings.map((meeting) {
                      final id = meeting['id'];
                      final prospectId =
                          meeting['prospect_aradial_id']?.toString();
                      final pData =
                          prospectId != null ? _prospects[prospectId] : null;
                      final name = _formatProspectName(pData);
                      final plan =
                          (pData != null &&
                                  pData['plan'] != null &&
                                  pData['plan'].toString().isNotEmpty)
                              ? pData['plan'].toString()
                              : AppStrings.notAvailable;
                      final address =
                          (pData != null &&
                                  pData['address'] != null &&
                                  pData['address'].toString().isNotEmpty)
                              ? pData['address'].toString()
                              : AppStrings.notAvailable;
                      final dateTime =
                          meeting['date_time1'] ??
                          meeting['appointment_date'] ??
                          meeting['dateTime1'] ??
                          'Fecha y Hora no disponible';
                      final phone =
                          (pData != null &&
                                  pData['phone'] != null &&
                                  pData['phone'].toString().isNotEmpty)
                              ? pData['address'].toString()
                              : (meeting['phone'] ??
                                      meeting['phone'] ??
                                      AppStrings.notAvailable)
                                  .toString();
                      return {
                        'id': id,
                        'Cliente': name,
                        'plan': plan,
                        'Dirección': address,
                        'Fecha y Hora': _formatDateTime(dateTime.toString()),
                        'telefono': phone,
                      };
                    }).toList(),
                title: 'Mis citas Instalacion',
                // onView para la vista detalles y comenzar intalacion
              ),
            ),
          ],
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
          'Panel de trabajador de Contratista',
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
              id = userId;
              if (userId == null || userId.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo obtener el usuario'),
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
                if (context.mounted) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Eliminar mi cuenta'),
                          content: const Text(
                            'Esta accion es irreversible. ¿Desea continuar?',
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
            tooltip: 'Cerrar sesion',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Cerrar sesion'),
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
      drawer: CustomWorkerDrawer(userId: id),
      body: _buildTable(),
      // Remove the following line if _buildWelcomeContent already includes _buildTable
      // Expanded(child: _buildTable()),
    );
  }
}
