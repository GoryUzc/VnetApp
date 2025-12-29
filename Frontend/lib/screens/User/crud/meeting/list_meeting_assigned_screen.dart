import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/widgets/adaptive_data_view.dart'; 
import 'package:vnet_agenda/screens/User/crud/meeting/detail_meeting_take_screen.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/list_meeting_unassegned_screen.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/services/others/contractor_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:intl/intl.dart';

class MeetingAssignedListScreen extends StatefulWidget {
  const MeetingAssignedListScreen({super.key});

  @override
  State<MeetingAssignedListScreen> createState() =>
      _MeetingAssignedListScreenState();
}

class _MeetingAssignedListScreenState extends State<MeetingAssignedListScreen> {
  final MeetingService _service = MeetingService();
  final ProspectService _prospectService = ProspectService();
  final UserServices _userServices = UserServices();
  final ContractorService _contractorService = ContractorService();
  final FranchiseService _franchiseService = FranchiseService();
  final Logger _logger = Logger();

  final Map<String, Map<String, dynamic>> _prospects = {};
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _contractors = {};
  final Map<String, Map<String, dynamic>> _franchises = {};

  List<Map<String, dynamic>> _meetings = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Variables para infinite scroll
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  final int _itemsPerPage = 10;
  List<Map<String, dynamic>> _displayedMeetings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefreshing = false, bool loadMore = false}) async {
    if (!isRefreshing && !loadMore) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _currentPage = 1;
        _displayedMeetings = [];
      });
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      // 1. Cargar reuniones principales
      final data = await _service.getAllMeetingAssigned();

      // Actualizar meetings inmediatamente
      setState(() {
        _meetings = data;

        // Simular paginación para infinite scroll
        if (!loadMore) {
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _meetings.length,
          );
          _displayedMeetings = _meetings.sublist(0, endIndex);
          _hasMore = endIndex < _meetings.length;
        } else {
          _currentPage++;
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _meetings.length,
          );
          _displayedMeetings = _meetings.sublist(0, endIndex);
          _hasMore = endIndex < _meetings.length;
        }
      });

      // 2. Cargar datos relacionados solo si hay meetings
      if (_meetings.isNotEmpty) {
        await _loadRelatedData();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }

      _logger.d(
        'Carga completada: ${_meetings.length} reuniones, ${_prospects.length} prospectos, ${_users.length} usuarios',
      );
    } catch (e) {
      _logger.e('Error en _load: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar(e);
    }
  }

  Future<void> _loadRelatedData() async {
    try {
      // 1. Extraer IDs únicos de los meetings mostrados
      final prospectIds =
          _displayedMeetings
              .map((m) => m['prospect_aradial_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      final userIds =
          _displayedMeetings
              .map((u) => u['user_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      final franchiseIds =
          _displayedMeetings
              .map((fid) => fid['franchise_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      // 2. Cargar prospectos
      final prospectFutures =
          prospectIds
              .where((pid) => !_prospects.containsKey(pid))
              .map((pid) => _loadProspect(pid))
              .toList();

      // 3. Cargar usuarios
      final userFutures =
          userIds
              .where((uid) => !_users.containsKey(uid))
              .map((uid) => _loadUser(uid))
              .toList();

      // 4. Ejecutar en paralelo
      await Future.wait([...prospectFutures, ...userFutures]);

      // 5. Cargar contratistas de los usuarios cargados
      final contractorIds =
          _users.values
              .map((u) => u['contractor_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      final contractorFutures =
          contractorIds
              .where((cid) => !_contractors.containsKey(cid))
              .map((cid) => _loadContractor(cid))
              .toList();

      if (contractorFutures.isNotEmpty) {
        await Future.wait(contractorFutures);
      }

      // 6. Cargar franquicias si no están cargadas
      if (franchiseIds.isNotEmpty && _franchises.isEmpty) {
        await _loadFranchises();
      }
    } catch (e) {
      _logger.w('Error cargando datos relacionados: $e');
    }
  }

  Future<void> _loadProspect(String pid) async {
    try {
      final pData = await _prospectService.getProspectDetails(pid);
      final map = Map<String, dynamic>.from(pData);

      if (mounted) {
        setState(() {
          _prospects[pid] = map['prospect'] ?? {};
        });
      }
    } catch (e) {
      _logger.w('No se pudo cargar prospecto $pid: $e');
      if (mounted) {
        setState(() {
          _prospects[pid] = {};
        });
      }
    }
  }

  Future<void> _loadUser(String uid) async {
    try {
      final uData = await _userServices.getUserDetails(uid);
      final mup = Map<String, dynamic>.from(uData);

      if (mounted) {
        setState(() {
          _users[uid] = mup;
        });
      }
    } catch (e) {
      _logger.w('No se pudo cargar usuario $uid: $e');
      if (mounted) {
        setState(() {
          _users[uid] = {};
        });
      }
    }
  }

  Future<void> _loadContractor(String cid) async {
    try {
      final cData = await _contractorService.getDetailContractor(cid);
      final mc = Map<String, dynamic>.from(cData);

      if (mounted) {
        setState(() {
          _contractors[cid] = mc;
        });
      }
    } catch (e) {
      _logger.w('No se pudo cargar contratista $cid: $e');
      if (mounted) {
        setState(() {
          _contractors[cid] = {};
        });
      }
    }
  }

  Future<void> _loadFranchises() async {
    try {
      final allFranchises = await _franchiseService.getAllFranchises();
      if (mounted) {
        setState(() {
          for (final f in allFranchises) {
            final fid = f['id']?.toString();
            if (fid != null && fid.isNotEmpty) {
              _franchises[fid] = f;
            }
          }
        });
      }
    } catch (e) {
      _logger.w('No se pudieron cargar franquicias: $e');
    }
  }

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

  String _formatName(Map<String, dynamic>? p) {
    if (p == null) return AppStrings.anonymous;
    final name = p['name']?.toString() ?? '';
    final lastName = p['last_name']?.toString() ?? '';
    final fullName = ('$name $lastName').trim();
    return fullName.isNotEmpty ? fullName : AppStrings.anonymous;
  }

  void _viewMeeting(String id) {
    final meeting = _displayedMeetings.firstWhere(
      (m) => m['id'].toString() == id,
      orElse: () => {},
    );

    final userId = meeting['user_id']?.toString();
    final prospectId = meeting['prospect_aradial_id']?.toString();
    final prospectData = prospectId != null ? _prospects[prospectId] : null;
    final userData = userId != null ? _users[userId] : null;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles de la Cita'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', meeting['id']?.toString()),
                  _buildDetailRow('Cliente', _formatName(prospectData)),
                  _buildDetailRow(
                    'Fecha y Hora',
                    _formatDateTime(meeting['date_time1']?.toString() ?? ''),
                  ),
                  _buildDetailRow('Técnico', _formatName(userData)),
                  _buildDetailRow('Plan', prospectData?['plan']?.toString()),
                  _buildDetailRow('Estado', meeting['status']?.toString()),
                  _buildDetailRow(
                    'Dirección',
                    prospectData?['address']?.toString() ??
                        meeting['address']?.toString(),
                  ),
                  _buildDetailRow(
                    'Observaciones',
                    meeting['observations']?.toString(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MeetingDeatilTakeScreen(
                            key: GlobalObjectKey(id),
                            meetingId: id,
                            userId: userId,
                          ),
                    ),
                  );
                },
                child: const Text('Gestionar Cita'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value ?? AppStrings.notAvailable,
              style: const TextStyle(color: Colors.grey),
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
          'Citas Asignadas a Contratistas',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isLoading && _displayedMeetings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _load(isRefreshing: true),
              tooltip: AppStrings.refresh,
            ),
        ],
        elevation: 4,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _displayedMeetings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando citas asignadas...',
              style: TextStyle(color: Colors.grey),
            ),
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

    return _buildAdaptiveDataView();
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
            'Error al cargar citas asignadas',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_ind, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'No hay citas asignadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Todas las citas están pendientes de asignación',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeetingUnassignedListScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Ver Citas sin Asignar',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveDataView() {
    // Preparamos los datos para AdaptiveDataView
    final formattedRows =
        _displayedMeetings.map((meeting) {
          final prospectId = meeting['prospect_aradial_id']?.toString();
          final prospectData =
              prospectId != null ? _prospects[prospectId] : null;

          final userId = meeting['user_id']?.toString();
          final userData = userId != null ? _users[userId] : null;

          final contractorId = userData?['contractor_id']?.toString();
          final contractorData =
              contractorId != null ? _contractors[contractorId] : null;

          final franchiseId = meeting['franchise_id']?.toString();
          final franchiseData =
              franchiseId != null ? _franchises[franchiseId] : null;

          final address =
              prospectData?['address']?.toString() ??
              meeting['address']?.toString() ??
              meeting['installation_address']?.toString() ??
              AppStrings.notAvailable;

          return {
            'id': meeting['id']?.toString() ?? '',
            'Cliente': _formatName(prospectData),
            'Fecha y Hora': _formatDateTime(
              meeting['date_time1']?.toString() ?? '',
            ),
            'Técnico': _formatName(userData),
            'Empresa':
                contractorData?['legal_name']?.toString() ??
                AppStrings.notAvailable,
            'Plan':
                prospectData?['plan']?.toString() ?? AppStrings.notAvailable,
            'Sucursal':
                franchiseData?['branch_office']?.toString() ??
                AppStrings.notAvailable,
            'Dirección': address,
            'Acciones': '', // Columna vacía para acciones
          };
        }).toList();

    return AdaptiveDataView(
      // CONFIGURACIÓN DE COLUMNAS
      columns: const [
        'Cliente',
        'Fecha y Hora',
        'Técnico',
        'Empresa',
        'Plan',
        'Sucursal',
        'Dirección',
        'Acciones',
      ],
      rows: formattedRows,
      title: 'Citas Asignadas a Contratistas',

      // ACCIONES
      onView: _viewMeeting,
      onEdit: null, // No hay edición en esta pantalla
      onDelete: null, // No hay eliminación en esta pantalla
      // INFINITE SCROLL
      onLoadMore: _loadMoreMeetings,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,

      // LABELS MEJORADOS
      columnLabels: const {
        'Cliente': 'Nombre del Cliente',
        'Fecha y Hora': 'Fecha y Hora de Cita',
        'Técnico': 'Técnico Asignado',
        'Empresa': 'Empresa Contratista',
        'Plan': 'Plan Contratado',
        'Sucursal': 'Sucursal/Franquicia',
        'Dirección': 'Dirección de Instalación',
        'Acciones': 'Acciones',
      },
    );
  }
}
