import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/widgets/adaptive_data_view.dart'; // ← CAMBIO IMPORT
import 'package:vnet_agenda/screens/User/crud/prospects/prospect_edit_screen.dart';
import 'package:vnet_agenda/screens/User/crud/prospects/prospect_create_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';

class ProspectListScreen extends StatefulWidget {
  const ProspectListScreen({super.key});

  @override
  State<ProspectListScreen> createState() => _ProspectListScreenState();
}

class _ProspectListScreenState extends State<ProspectListScreen> {
  final ProspectService _prospectService = ProspectService();
  final FranchiseService _franchiseService = FranchiseService();

  final Map<int, String> _franchiseNames = {};
  List<Map<String, dynamic>> _prospects = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Variables para infinite scroll
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  final int _itemsPerPage = 10;
  List<Map<String, dynamic>> _displayedProspects = [];

  @override
  void initState() {
    super.initState();
    _loadProspects();
    _loadFranchises();
  }

  Future<void> _loadProspects({
    bool isRefreshing = false,
    bool loadMore = false,
  }) async {
    if (!isRefreshing && !loadMore) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _currentPage = 1;
        _displayedProspects = [];
      });
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
      await Future.delayed(const Duration(milliseconds: 500)); // Simula carga
    }

    try {
      final prospects = await _prospectService.getAllProspects();
      final validProspects =
          prospects.whereType<Map<String, dynamic>>().toList();

      setState(() {
        _prospects = validProspects;

        // Simular paginación para infinite scroll
        if (!loadMore) {
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _prospects.length,
          );
          _displayedProspects = _prospects.sublist(0, endIndex);
          _hasMore = endIndex < _prospects.length;
        } else {
          _currentPage++;
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _prospects.length,
          );
          _displayedProspects = _prospects.sublist(0, endIndex);
          _hasMore = endIndex < _prospects.length;
        }

        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar(e);
    }
  }

  void _loadMoreProspects() {
    if (!_isLoadingMore && _hasMore) {
      _loadProspects(loadMore: true);
    }
  }

  Future<void> _loadFranchises() async {
    try {
      final franchises = await _franchiseService.getAllFranchises();
      setState(() {
        for (final f in franchises) {
          final dynamic id = f['id'];
          int? key;
          if (id is int) {
            key = id;
          } else if (id is String) {
            key = int.tryParse(id);
          }
          if (key != null) {
            _franchiseNames[key] =
                (f['branch_office'] ??
                        f['name'] ??
                        AppStrings.untitledFranchise)
                    .toString();
          }
        }
      });
    } catch (_) {
      // Silenciar errores
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

  Future<void> _deleteProspect(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.confirmDeleteTitle),
            content: Text(AppStrings.confirmDeleteMessage(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  AppStrings.delete,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _prospectService.deleteProspect(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.prospectDeleted),
            backgroundColor: Colors.green,
          ),
        );
        _loadProspects(); // Recargar lista
      } catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  void _editProspect(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProspectEditScreen(prospectId: id),
      ),
    ).then((_) => _loadProspects());
  }

  void _viewProspect(String id) {
    final prospect = _displayedProspects.firstWhere(
      (p) => p['id'].toString() == id,
      orElse: () => {},
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles del Prospecto'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', prospect['id']?.toString()),
                  _buildDetailRow('Nombre', _formatName(prospect)),
                  _buildDetailRow(
                    'Documento',
                    prospect['document']?.toString(),
                  ),
                  _buildDetailRow('Correo', prospect['email']?.toString()),
                  _buildDetailRow('Teléfono', prospect['phone']?.toString()),
                  _buildDetailRow('Franquicia', _getFranchiseName(prospect)),
                  _buildDetailRow('Plan', prospect['plan']?.toString()),
                  _buildDetailRow(
                    'Estado Red',
                    prospect['status_red']?.toString(),
                  ),
                  if (prospect['address'] != null)
                    _buildDetailRow(
                      'Dirección',
                      prospect['address']?.toString(),
                    ),
                  if (prospect['observations'] != null)
                    _buildDetailRow(
                      'Observaciones',
                      prospect['observations']?.toString(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
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

  String _getFranchiseName(Map<String, dynamic> prospect) {
    final dynamic fobj = prospect['franchise'];
    if (fobj is Map) {
      final dynamic name = fobj['branch_office'] ?? fobj['name'];
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }

    final dynamic fidDyn =
        prospect['franchise_id'] ?? prospect['franchises_id'];
    int? fid;
    if (fidDyn is int) {
      fid = fidDyn;
    } else if (fidDyn is String) {
      fid = int.tryParse(fidDyn);
    }
    if (fid != null) {
      final lookup = _franchiseNames[fid];
      if (lookup != null && lookup.isNotEmpty) {
        return lookup;
      }
    }
    return AppStrings.notAvailable;
  }

  String _formatName(Map<String, dynamic> prospect) {
    final firstName = prospect['name'] ?? '';
    final lastName = prospect['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : AppStrings.anonymous;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Gestión de Prospectos',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isLoading && _displayedProspects.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadProspects(isRefreshing: true),
              tooltip: AppStrings.refresh,
            ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProspectCreateScreen(),
                ),
              ).then((_) => _loadProspects());
            },
            tooltip: AppStrings.addProspect,
          ),
        ],
        elevation: 4,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _displayedProspects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando prospectos...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_displayedProspects.isEmpty) {
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
            AppStrings.errorLoadingProspects,
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
            onPressed: () => _loadProspects(),
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
          const Icon(Icons.people_alt, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            AppStrings.noProspectsRegistered,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            AppStrings.createFirstProspectDescription,
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProspectCreateScreen(),
                ),
              ).then((_) => _loadProspects());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              AppStrings.createFirstProspect,
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
        _displayedProspects.map((prospect) {
          return {
            'id': prospect['id']?.toString() ?? '',
            'ID': prospect['id']?.toString() ?? '',
            'Nombre': _formatName(prospect),
            'Documento':
                (prospect['document'] ?? AppStrings.notAvailable).toString(),
            'Correo': (prospect['email'] ?? AppStrings.notAvailable).toString(),
            'Teléfono':
                (prospect['phone'] ?? AppStrings.notAvailable).toString(),
            'Franquicia': _getFranchiseName(prospect),
            'Plan': (prospect['plan'] ?? AppStrings.notAvailable).toString(),
            'Estado':
                (prospect['status_red'] ?? AppStrings.notAvailable).toString(),
            'Acciones': '', // Columna vacía para acciones
          };
        }).toList();

    return AdaptiveDataView(
      // CONFIGURACIÓN DE COLUMNAS
      columns: const [
        'ID',
        'Nombre',
        'Documento',
        'Correo',
        'Teléfono',
        'Franquicia',
        'Plan',
        'Estado',
        'Acciones',
      ],
      rows: formattedRows,
      title: 'Lista de Prospectos',

      // ACCIONES CRUD
      onView: _viewProspect,
      onEdit: _editProspect,
      onDelete: (id) {
        final prospect = _displayedProspects.firstWhere(
          (p) => p['id'].toString() == id,
          orElse: () => {},
        );
        final name = _formatName(prospect);
        _deleteProspect(id, name.isNotEmpty ? name : 'prospecto');
      },

      // INFINITE SCROLL
      onLoadMore: _loadMoreProspects,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,

      // LABELS MEJORADOS
      columnLabels: const {
        'ID': 'ID',
        'Nombre': 'Nombre Completo',
        'Documento': 'Documento de Identidad',
        'Correo': 'Correo Electrónico',
        'Teléfono': 'Teléfono',
        'Franquicia': 'Franquicia',
        'Plan': 'Plan Contratado',
        'Estado': 'Estado de Red',
        'Acciones': 'Acciones',
      },
    );
  }
}
