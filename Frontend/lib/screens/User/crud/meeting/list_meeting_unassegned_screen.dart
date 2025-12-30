import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/widgets/adaptive_data_view.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/detail_meeting_take_screen.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:intl/intl.dart';

class MeetingUnassignedListScreen extends StatefulWidget {
  final String? userId;
  const MeetingUnassignedListScreen({super.key, this.userId});

  @override
  State<MeetingUnassignedListScreen> createState() =>
      _MeetingUnassignedListScreenState();
}

class _MeetingUnassignedListScreenState
    extends State<MeetingUnassignedListScreen> {
  final MeetingService _service = MeetingService();
  final ProspectService _prospectService = ProspectService();
  final FranchiseService _franchiseService = FranchiseService();
  final Logger _logger = Logger();

  // Cache de detalles
  final Map<String, Map<String, dynamic>> _prospectCache = {};
  final Map<String, Map<String, dynamic>> _franchisesCache = {};

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

    _logger.d('ID del usuario: ${widget.userId}');

    try {
      // 1. Obtener citas sin asignar
      final meetings = await _service.getAllMeetingUnassigned();

      setState(() {
        _meetings = meetings;

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

      _logger.d('Carga completada: ${_meetings.length} citas sin asignar');
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

      final franchiseIds =
          _displayedMeetings
              .map((fid) => fid['franchise_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      // 2. Cargar prospectos
      final prospectFutures =
          prospectIds
              .where((pid) => !_prospectCache.containsKey(pid))
              .map((pid) => _loadProspect(pid))
              .toList();

      // 3. Ejecutar en paralelo
      if (prospectFutures.isNotEmpty) {
        await Future.wait(prospectFutures);
      }

      // 4. Cargar franquicias si no están cargadas
      if (franchiseIds.isNotEmpty && _franchisesCache.isEmpty) {
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
          _prospectCache[pid] = map['prospect'] ?? {};
        });
      }
      _logger.d('Prospecto cargado: $pid');
    } catch (e) {
      _logger.w('No se pudo cargar prospecto $pid: $e');
      if (mounted) {
        setState(() {
          _prospectCache[pid] = {};
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
              _franchisesCache[fid] = f;
            }
          }
        });
      }
      _logger.d('Franquicias cargadas: ${_franchisesCache.length}');
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

  String _formatProspectName(Map<String, dynamic>? p) {
    if (p == null) return AppStrings.anonymous;
    final first = p['name']?.toString() ?? '';
    final last = p['last_name']?.toString() ?? '';
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : AppStrings.anonymous;
  }

  void _viewMeeting(String id) {
    final meeting = _displayedMeetings.firstWhere(
      (m) => m['id'].toString() == id,
      orElse: () => {},
    );

    final prospectId = meeting['prospect_aradial_id']?.toString();
    final prospectData = prospectId != null ? _prospectCache[prospectId] : null;
    final franchiseId = meeting['franchise_id']?.toString();
    final franchiseData =
        franchiseId != null ? _franchisesCache[franchiseId] : null;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles de Cita sin Asignar'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', meeting['id']?.toString()),
                  _buildDetailRow('Cliente', _formatProspectName(prospectData)),
                  _buildDetailRow('Plan', prospectData?['plan']?.toString()),
                  _buildDetailRow(
                    'Fecha y Hora',
                    _formatDateTime(meeting['date_time1']?.toString() ?? ''),
                  ),
                  _buildDetailRow(
                    'Dirección',
                    prospectData?['address']?.toString() ??
                        meeting['address']?.toString() ??
                        meeting['installation_address']?.toString(),
                  ),
                  _buildDetailRow(
                    'Sucursal',
                    franchiseData?['branch_office']?.toString(),
                  ),
                  _buildDetailRow(
                    'Documento',
                    prospectData?['document']?.toString(),
                  ),
                  _buildDetailRow(
                    'Teléfono',
                    prospectData?['phone']?.toString(),
                  ),
                  _buildDetailRow('Correo', prospectData?['email']?.toString()),
                  _buildDetailRow(
                    'Observaciones',
                    meeting['observations']?.toString(),
                  ),
                  _buildDetailRow('Estado', '⏳ Pendiente de Asignación'),
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
                            key: GlobalKey(),
                            meetingId: id,
                            userId: widget.userId,
                          ),
                    ),
                  ).then((_) => _load()); // Recargar después de volver
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Tomar Instalación'),
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
          'Citas sin Asignar',
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
              'Cargando citas sin asignar...',
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
            'Error al cargar citas sin asignar',
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text(
            '¡Excelente! No hay citas sin asignar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Todas las citas tienen técnico asignado',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
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
              prospectId != null ? _prospectCache[prospectId] : null;

          final franchiseId = meeting['franchise_id']?.toString();
          final franchiseData =
              franchiseId != null ? _franchisesCache[franchiseId] : null;

          final address =
              prospectData?['address']?.toString() ??
              meeting['address']?.toString() ??
              meeting['installation_address']?.toString() ??
              AppStrings.notAvailable;

          return {
            'id': meeting['id']?.toString() ?? '',
            'Cliente': _formatProspectName(prospectData),
            'Plan':
                prospectData?['plan']?.toString() ?? AppStrings.notAvailable,
            'Fecha y Hora': _formatDateTime(
              meeting['date_time1']?.toString() ?? '',
            ),
            'Dirección': address,
            'Sucursal':
                franchiseData?['branch_office']?.toString() ??
                AppStrings.notAvailable,
            'Acciones': '', // Columna vacía para acciones
          };
        }).toList();

    return AdaptiveDataView(
      // CONFIGURACIÓN DE COLUMNAS
      columns: const [
        'Cliente',
        'Plan',
        'Fecha y Hora',
        'Dirección',
        'Sucursal',
        'Acciones',
      ],
      rows: formattedRows,
      title: 'Citas sin Asignar',

      // ACCIONES (solo vista, no edición/eliminación)
      onView: _viewMeeting,
      onEdit: null, // No edición directa
      onDelete: null, // No eliminación en esta vista
      // INFINITE SCROLL
      onLoadMore: _loadMoreMeetings,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,

      // LABELS MEJORADOS
      columnLabels: const {
        'Cliente': 'Nombre del Cliente',
        'Plan': 'Plan Contratado',
        'Fecha y Hora': 'Fecha y Hora de Cita',
        'Dirección': 'Dirección de Instalación',
        'Sucursal': 'Sucursal/Franquicia',
        'Acciones': 'Acciones',
      },
    );
  }
}
