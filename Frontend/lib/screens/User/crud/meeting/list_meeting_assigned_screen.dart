import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/detail_meeting_take_screen.dart';
import 'package:vnet_agenda/screens/User/crud/meeting/list_meeting_unassegned_screen.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/services/others/contractor_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';
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
      // 1. Cargar reuniones principales
      final data = await _service.getAllMeetingAssigned();

      // Actualizar meetings inmediatamente
      setState(() {
        _meetings = data;
      });

      // 2. Extraer IDs únicos
      final prospectIds =
          _meetings
              .map((m) => m['prospect_aradial_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      final userIds =
          _meetings
              .map((u) => u['user_id']?.toString())
              .where((ide) => ide != null && ide.isNotEmpty)
              .cast<String>()
              .toSet();

      final franchiseIds =
          _meetings
              .map((fid) => fid['franchise_id']?.toString())
              .where((fid) => fid != null && fid.isNotEmpty)
              .cast<String>()
              .toSet();

      // 3. Cargar prospectos y usuarios en paralelo
      final futuresP = <Future<void>>[];
      for (final pid in prospectIds) {
        if (!_prospects.containsKey(pid)) {
          futuresP.add(
            _prospectService
                .getProspectDetails(pid)
                .then((pData) {
                  final map = Map<String, dynamic>.from(pData);
                  _logger.d('Prospecto cargado: $map');

                  setState(() {
                    _prospects[pid] = map['prospect'] ?? {};
                  });
                })
                .catchError((e) {
                  _logger.w('No se pudo cargar prospecto $pid: $e');
                  setState(() {
                    _prospects[pid] = {};
                  });
                }),
          );
        }
      }

      final futuresU = <Future<void>>[];
      for (final uid in userIds) {
        if (!_users.containsKey(uid)) {
          futuresU.add(
            _userServices
                .getUserDetails(uid)
                .then((uData) {
                  final mup = Map<String, dynamic>.from(uData);
                  _logger.d('Usuario cargado: $mup');

                  setState(() {
                    _users[uid] = mup;
                  });
                })
                .catchError((e) {
                  _logger.w('No se pudo cargar usuario $uid: $e');
                  setState(() {
                    _users[uid] = {};
                  });
                }),
          );
        }
      }

      // 4. ESPERAR a que todas las peticiones se completen
      await Future.wait([...futuresP, ...futuresU]);

      // 4.1 Cargar contratistas asociados a los usuarios
      final contractorIds =
          _users.values
              .map((u) => u['contractor_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

      final futuresC = <Future<void>>[];
      for (final cid in contractorIds) {
        if (!_contractors.containsKey(cid)) {
          futuresC.add(
            _contractorService
                .getDetailContractor(cid)
                .then((cData) {
                  final mc = Map<String, dynamic>.from(cData);
                  _logger.d('Contratista cargado: $mc');
                  setState(() {
                    _contractors[cid] = mc;
                  });
                })
                .catchError((e) {
                  _logger.w('No se pudo cargar contratista $cid: $e');
                  setState(() {
                    _contractors[cid] = {};
                  });
                }),
          );
        }
      }
      if (futuresC.isNotEmpty) {
        await Future.wait(futuresC);
      }
      if (franchiseIds.isNotEmpty) {
        try {
          final allFranchises = await _franchiseService.getAllFranchises();
          setState(() {
            for (final f in allFranchises) {
              final fid = f['id']?.toString();
              if (fid != null && fid.isNotEmpty) {
                _franchises[fid] = f;
              }
            }
          });
        } catch (e) {
          _logger.w('No se pudieron cargar franquicias: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _logger.d(
        'Carga completada: ${_meetings.length} reuniones, ${_prospects.length} prospectos, ${_users.length} usuarios, ${_contractors.length} empresas',
      );
    } catch (e) {
      _logger.e('Error en _load: $e');
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

  String _formatName(Map<String, dynamic>? p) {
    if (p == null) return AppStrings.anonymous;
    final name = p['name']?.toString() ?? '';
    final lastName = p['last_name']?.toString() ?? '';
    final fullName = ('$name $lastName').trim();
    return fullName.isNotEmpty ? fullName : AppStrings.anonymous;
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
              // Navegar a citas sin asignar
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

  Widget _buildTable() {
    return RefreshIndicator(
      onRefresh: () => _load(isRefreshing: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                child: DataTableCustom(
                  columns: const [
                    'Cliente',
                    'Fecha y Hora',
                    'Técnico',
                    'Empresa',
                    'plan',
                    'Sucursal',
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
                        final clientName = _formatName(pData);
                        final dateTime =
                            meeting['date_time1'] ?? 'Fecha no disponible';
                        final userId = meeting['user_id']?.toString();
                        _logger.d(' 1 Id user: $userId');
                        final uData = userId != null ? _users[userId] : null;
                        final user = _users[userId];
                        _logger.d('2: $user');
                        final technician = _formatName(uData);
                        _logger.d('3: $technician');

                        final contractorId =
                            uData != null
                                ? uData['contractor_id']?.toString()
                                : null;
                        final cData =
                            contractorId != null
                                ? _contractors[contractorId]
                                : null;
                        final company =
                            (cData != null &&
                                    cData['legal_name'] != null &&
                                    cData['legal_name'].toString().isNotEmpty)
                                ? cData['legal_name'].toString()
                                : AppStrings.notAvailable;

                        final franchiseId = meeting['franchise_id']?.toString();
                        _logger.d('1: $franchiseId');
                        final fData =
                            franchiseId != null
                                ? _franchises[franchiseId]
                                : null;
                        _logger.d('2: $fData');
                        final franchiseName =
                            (fData != null && fData['branch_office'] != null)
                                ? fData['branch_office'].toString()
                                : AppStrings.notAvailable;
                        _logger.d('3: $franchiseName');

                        final address =
                            (pData != null &&
                                    pData['address'] != null &&
                                    pData['address'].toString().isNotEmpty)
                                ? pData['address'].toString()
                                : (meeting['address'] ??
                                        meeting['installation_address'] ??
                                        AppStrings.notAvailable)
                                    .toString();
                        final plan =
                            (pData != null &&
                                    pData['plan'] != null &&
                                    pData['plan'].toString().isNotEmpty)
                                ? pData['plan'].toString()
                                : AppStrings.notAvailable;

                        return {
                          'id': id,
                          'Cliente': clientName.toString(),
                          'Fecha y Hora': _formatDateTime(dateTime.toString()),
                          'Técnico': technician.toString(),
                          'Empresa': company.toString(),
                          'plan': plan.toString(),
                          'Sucursal': franchiseName.toString(),
                          'Dirección': address.toString(),
                        };
                      }).toList(),
                  onView: (id) {
                    // Buscar la cita seleccionada por su id
                    final meeting = _meetings.firstWhere(
                      (m) => m['id'].toString() == id,
                      orElse: () => {},
                    );
                    // Extraer el user_id de la cita
                    final userId = meeting['user_id']?.toString();

                    // Navegar a la pantalla de detalles pasando meetingId y userId
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
