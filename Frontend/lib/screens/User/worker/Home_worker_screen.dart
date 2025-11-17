import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/detail_meeting_install_screen.dart';
// import 'package:vnet_agenda/screens/User/crud/order/order_edit_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
// import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';
import 'package:vnet_agenda/widgets/worker_drawer.dart';

class HomeWorkerScreen extends StatefulWidget {
  const HomeWorkerScreen({super.key});

  @override
  State<HomeWorkerScreen> createState() => _HomeWorkerScreenState();
}

class _HomeWorkerScreenState extends State<HomeWorkerScreen> {
  final ProspectService _prospectService = ProspectService();
  final MeetingService _meetingService = MeetingService();
  // final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  final Map<String, Map<String, dynamic>> _prospects = {};
  List<Map<String, dynamic>> _meetings = [];
  List<Map<String, dynamic>> _meetingsInProcess = [];
  String idUser = '';
  String idProspect = '';
  String idOrder = '';
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
        _errorMessage = '';
        _hasError = false;
      });
    }
    try {
      final user = await _authService.getUserId();
      idUser = user ?? 'No especificado';
      _logger.d('ID => $idUser');
      final data1 = await _meetingService.getAllMeetingUser();
      _meetings = data1;

      final data2 = await _meetingService.getAllMeetingUserProcess();
      _meetingsInProcess = data2;
      // idProspect se determinará por fila al construir tablas
      final prospectIds =
          _meetings
              .map((m) => m['prospect_aradial_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
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
          _meetings = data1;
          _meetingsInProcess = data2;
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
    final full = ('$first $last').trim();
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
                  'Telefono',
                  'Dirección',
                  'Acciones',
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
                              ? pData['phone'].toString()
                              : (meeting['phone'] ??
                                      meeting['phone'] ??
                                      AppStrings.notAvailable)
                                  .toString();
                      return {
                        'id': id,
                        'Cliente': name,
                        'Plan': plan,
                        'Dirección': address,
                        'Fecha y Hora': _formatDateTime(dateTime.toString()),
                        'telefono': phone,
                      };
                    }).toList(),
                title: 'Mis citas Instalacion',
                // onView para la vista detalles y comenzar intalacion
                onView: (id) {
                  // final meeting = _meetings.firstWhere(
                  //   (m) => m[id].toString() == id,
                  //   orElse: () => {},
                  // );

                  // _logger.d('cita detalles: $meeting');

                  // final userId = meeting['user_id']?.toString();

                  // Navegar a la pantalla detalles de la cita
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DetailMeetingInstallScreen(
                            meetingId: id.toString() ?? '',
                            userId: idUser,
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_meetings.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTable();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text(
            'Tome una cita de instalacion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: ListView(
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar citas de instalacion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _load(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              AppStrings.retry,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
          // Botón para recargar manualmente
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _load(isRefreshing: true),
            tooltip: 'Recargar',
          ),
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
      drawer: CustomWorkerDrawer(userId: idUser),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección: Mis citas Instalación
                  Expanded(child: _buildContent()),
                  // const Divider(height: 1),
                  // // Sección: Citas en proceso
                  // Expanded(child: _builTabletInProcess()),
                ],
              ),
    );
  }
}
