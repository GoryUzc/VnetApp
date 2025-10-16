import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/detail_meeting_screen.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';
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

  // Cache de detalles de prospectos por ID
  final Map<String, Map<String, dynamic>> _prospectCache = {};
  final Map<String, Map<String, dynamic>> _franchisesCache = {};
  String? idMeeting;
  List<Map<String, dynamic>> _meetings = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      //  Obtener citas sin asignar
      final meetings = await _service.getAllMeetingUnassigned();
      setState(() {
        _meetings = meetings;
      });

      //  Recolectar IDs de prospectos únicos presentes en las citas
      final prospectIds =
          _meetings
              .map((m) => m['prospect_aradial_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      final franchiseIds =
          _meetings
              .map((fid) => fid['franchise_id']?.toString())
              .where((fid) => fid != null && fid.isNotEmpty)
              .cast<String>()
              .toSet();

      //  Cargar en paralelo los detalles de prospectos que no estén en caché
      final futures = <Future<void>>[];
      for (final pid in prospectIds) {
        if (!_prospectCache.containsKey(pid)) {
          futures.add(
            _prospectService
                .getProspectDetails(pid)
                .then((pData) {
                  // Asegurar que sea un Map<String, dynamic>
                  final map = Map<String, dynamic>.from(pData);
                  _logger.d('1 $map');
                  _prospectCache[pid] = map['prospect'];
                  _logger.d('2 $_prospectCache');
                })
                .catchError((e) {
                  _logger.w('No se pudo cargar prospecto $pid: $e');
                  _prospectCache[pid] = {};
                  _logger.d('Los prospects $_prospectCache');
                }),
          );
        }
      }
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      if (franchiseIds.isNotEmpty) {
        try {
          final allFranchises = await _franchiseService.getAllFranchises();
          setState(() {
            for (final f in allFranchises) {
              final fid = f['id']?.toString();
              if (fid != null && fid.isNotEmpty) {
                _franchisesCache[fid] = f;
              }
            }
          });
        } catch (e) {
          _logger.w('No se pudieron cargar franquicias: $e');
        }
      }

      if (mounted) {
        setState(() {
          _meetings = meetings;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
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
          if (!_isLoading && _meetings.isNotEmpty)
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
    if (_isLoading) {
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

  Widget _buildErrorState() {
    return Center(
      child: ListView(
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

  Widget _buildTable() {
    return RefreshIndicator(
      onRefresh: () => _load(isRefreshing: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: DataTableCustom(
                columns: const [
                  'Cliente',
                  'Plan',
                  'Fecha y Hora',
                  'Dirección',
                  'Sucursal',
                  'Acciones',
                ],
                rows:
                    _meetings.map((meeting) {
                      final id = meeting['id'].toString();
                      final dateTime =
                          meeting['date_time1'] ?? 'Fecha no disponible';

                      final prospectId =
                          meeting['prospect_aradial_id']?.toString();
                      final pData =
                          prospectId != null
                              ? _prospectCache[prospectId]
                              : null;
                      final cliente = _formatProspectName(pData);
                      final direccion =
                          (pData != null &&
                                  pData['address'] != null &&
                                  pData['address'].toString().isNotEmpty)
                              ? pData['address'].toString()
                              : (meeting['address'] ??
                                      meeting['installation_address'] ??
                                      AppStrings.notAvailable)
                                  .toString();

                      final franchiseId = meeting['franchise_id']?.toString();
                      _logger.d('1: $franchiseId');
                      final fData =
                          franchiseId != null
                              ? _franchisesCache[franchiseId]
                              : null;
                      _logger.d('2: $fData');
                      final franchiseName =
                          (fData! is Map &&
                                  fData['branch_office'] != null &&
                                  fData['branch_office'].toString().isNotEmpty)
                              ? fData['branch_office'].toString()
                              : (fData is String && fData.isNotEmpty
                                  ? fData
                                  : AppStrings.notAvailable);
                      _logger.d('3: $franchiseName');

                      final plan =
                          (pData != null &&
                                  pData['plan'] != null &&
                                  pData['plan'].toString().isNotEmpty)
                              ? pData['plan'].toString()
                              : AppStrings.notAvailable;

                      return {
                        'id': id,
                        'Cliente': cliente,
                        'Plan': plan,
                        'Fecha y Hora': _formatDateTime(dateTime.toString()),
                        'Dirección': direccion,
                        'Sucursal': franchiseName.toString(),
                      };
                    }).toList(),
                onView: (id) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MeetingDeatilScreen(
                            key: GlobalKey(),
                            meetingId: id,
                            userId: widget.userId,
                          ),
                    ),
                  );
                },
                onDelete: null, // No permitir eliminar en esta vista
              ),
            ),
          ],
        ),
      ),
    );
  }
}
