import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:logger/web.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/detail_meeting_install_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
// import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/widgets/contractor_drawer.dart';
import 'package:vnet_agenda/widgets/adaptive_data_view.dart'; // ← CAMBIA ESTE IMPORT

class HomeContractorScreen extends StatefulWidget {
  const HomeContractorScreen({super.key});

  @override
  State<HomeContractorScreen> createState() => _HomeContractorScreenState();
}

class _HomeContractorScreenState extends State<HomeContractorScreen> {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final MeetingService _meetingService = MeetingService();
  final ProspectService _prospectService = ProspectService();
  final Map<String, Map<String, dynamic>> _prospects = {};
  List<Map<String, dynamic>> _meetings = [];
  String _idUser = '';
  String idProspect = '';
  String idOrder = '';
  bool _loading = false;
  String _errorMessage = '';
  bool _hasError = false;

  // Variables para infinite scroll (SIMULADO ya que tu API no tiene paginación)
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = false; // En false porque tu API trae todo de una vez
  final int _itemsPerPage = 10;
  List<Map<String, dynamic>> _displayedMeetings = []; // Para simular paginación

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefreshing = false, bool loadMore = false}) async {
    if (!isRefreshing && !loadMore) {
      setState(() {
        _loading = true;
        _errorMessage = '';
        _hasError = false;
        _currentPage = 1;
        _displayedMeetings = [];
      });
    }

    // Si es para cargar más (simulado)
    if (loadMore) {
      setState(() => _isLoadingMore = true);
      await Future.delayed(const Duration(seconds: 1)); // Simula carga
    }

    try {
      final user = await _authService.getUserId() ?? 'No especificado';
      _logger.d('ID => $user');
      _idUser = user;

      // Tu API actual trae todo de una vez
      if (!loadMore) {
        final data = await _meetingService.getAllMeetingUser();
        _meetings = data;

        // Para simular paginación, mostramos solo los primeros N items
        const startIndex = 0;
        final endIndex = (_currentPage * _itemsPerPage).clamp(
          0,
          _meetings.length,
        );
        _displayedMeetings = _meetings.sublist(startIndex, endIndex);
        _hasMore = endIndex < _meetings.length;
      } else {
        // Para "cargar más" - mostramos más items de los ya cargados
        _currentPage++;
        const startIndex = 0;
        final endIndex = (_currentPage * _itemsPerPage).clamp(
          0,
          _meetings.length,
        );
        _displayedMeetings = _meetings.sublist(startIndex, endIndex);
        _hasMore = endIndex < _meetings.length;
      }

      // Cargar detalles de prospectos
      final prospectIds =
          _displayedMeetings
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
                  final map = Map<String, dynamic>.from(pData);
                  _prospects[pid] = map['prospect'];
                })
                .catchError((e) {
                  _logger.w('No se pudo cargar prospecto $pid: $e');
                  _prospects[pid] = {};
                }),
          );
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _isLoadingMore = false;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar(e);
    }
  }

  // Función para cargar más datos (simulada)
  void _loadMoreMeetings() {
    if (!_isLoadingMore && _hasMore) {
      _load(loadMore: true);
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
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : AppStrings.anonymous;
  }

  Widget _buildTable() {
    // Preparamos los datos para AdaptiveDataView
    const String title = 'Citas de instalacion';
    final formattedRows =
        _displayedMeetings.map((meeting) {
          final id = meeting['id']?.toString() ?? '';
          final prospectId = meeting['prospect_aradial_id']?.toString();
          final pData = prospectId != null ? _prospects[prospectId] : null;
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
            'plan': plan,
            'Fecha y Hora': _formatDateTime(dateTime.toString()),
            'Telefono': phone,
            'Dirección': address,
          };
        }).toList();

    return RefreshIndicator(
      semanticsLabel: 'Mis Citas de Instalacion',
      onRefresh: () => _load(isRefreshing: true),
      child: AdaptiveDataView(
        // PARÁMETROS REQUERIDOS
        columns: const [
          'Cliente',
          'plan',
          'Fecha y Hora',
          'Telefono',
          'Dirección',
          'Acciones',
        ],
        rows: formattedRows,
        title: title,

        // ACCIÓN PRINCIPAL (VER DETALLES)
        onView: (id) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DetailMeetingInstallScreen(
                    meetingId: id,
                    userId: _idUser,
                  ),
            ),
          );
        },

        // ACCIONES OPCIONALES (usamos placeholders ya que no las necesitas)
        onEdit: null,

        onDelete: null,

        // CONFIGURACIÓN DE INFINITE SCROLL
        onLoadMore: _loadMoreMeetings,
        isLoadingMore: _isLoadingMore,
        hasMore: _hasMore,

        // MEJORES NOMBRES PARA LAS COLUMNAS
        columnLabels: const {
          'Cliente': 'Cliente',
          'plan': 'Plan Contratado',
          'Fecha y Hora': 'Fecha y Hora',
          'Telefono': 'Teléfono',
          'Dirección': 'Dirección',
          'Acciones': 'Acciones',
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _displayedMeetings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando citas...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_displayedMeetings.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTable();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_turned_in, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'Tome una cita de instalacion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _load(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text(
              'Recargar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
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
          'Panel de Contratista',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.refresh, color: Colors.white),
          //   onPressed: () => _load(isRefreshing: true),
          //   tooltip: 'Recargar',
          // ),
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
                //   } else if (value == 'delete') {
                //     if (context.mounted) {
                //       final confirmed = await showDialog<bool>(
                //         context: context,
                //         builder:
                //             (ctx) => AlertDialog(
                //               title: const Text('Eliminar mi cuenta'),
                //               content: const Text(
                //                 'Esta acción es irreversible. ¿Desea continuar?',
                //               ),
                //               actions: [
                //                 TextButton(
                //                   onPressed: () => Navigator.pop(ctx, false),
                //                   child: const Text('Cancelar'),
                //                 ),
                //                 TextButton(
                //                   onPressed: () => Navigator.pop(ctx, true),
                //                   child: const Text(
                //                     'Eliminar',
                //                     style: TextStyle(color: Colors.red),
                //                   ),
                //                 ),
                //               ],
                //             ),
                //       );

                //       if (confirmed == true) {
                //         try {
                //           await UserServices().deleteUser(userId);
                //           await AuthService().logout();
                //           if (context.mounted) {
                //             Navigator.of(context).pushAndRemoveUntil(
                //               MaterialPageRoute(
                //                 builder: (_) => const InitSelectUserScreen(),
                //               ),
                //               (route) => false,
                //             );
                //           }
                //         } catch (e) {
                //           if (context.mounted) {
                //             ScaffoldMessenger.of(
                //               context,
                //             ).showSnackBar(SnackBar(content: Text('Error: $e')));
                //           }
                //         }
                //       }
                //     }
              }
            },
            itemBuilder:
                (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar mi perfil'),
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
      drawer: CustomContractorDrawer(userId: _idUser),
      body: _buildContent(),
    );
  }

  // Widget _buildWelcomeContent() {
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       const Text(
  //         "Bienvenido al Sistema VNET",
  //         style: TextStyle(
  //           fontSize: 12,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.grey,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //       const SizedBox(height: 10),
  //       Text(
  //         "Citas de Instalaciones de Fibra Óptica",
  //         style: TextStyle(fontSize: 10, color: Colors.grey[600]),
  //         textAlign: TextAlign.center,
  //       ),

  //       const SizedBox(height: 10),
  //       _buildContent(),
  //     ],
  //   );
  // }
}
