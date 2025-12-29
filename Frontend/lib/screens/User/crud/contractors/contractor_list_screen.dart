import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/contractor_services.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/widgets/adaptive_data_view.dart';
import 'package:vnet_agenda/screens/User/crud/contractors/contractor_create_screen.dart';
import 'package:vnet_agenda/screens/User/crud/contractors/contractor_edit_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';

class ContractorListScreen extends StatefulWidget {
  const ContractorListScreen({super.key});

  @override
  State<ContractorListScreen> createState() => _ContractorListScreenState();
}

class _ContractorListScreenState extends State<ContractorListScreen> {
  final ContractorServices _service = ContractorServices();
  final FranchiseService _franchiseService = FranchiseService();

  final Map<int, String> _franchiseNames = {};
  List<Map<String, dynamic>> _contractors = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  final int _itemsPerPage = 10;
  List<Map<String, dynamic>> _displayedContractors = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadFranchises();
  }

  Future<void> _load({bool isRefreshing = false, bool loadMore = false}) async {
    if (!isRefreshing && !loadMore) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _currentPage = 1;
        _displayedContractors = [];
      });
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
      await Future.delayed(const Duration(milliseconds: 500)); // Simula carga
    }

    try {
      final data = await _service.getAllContractors();

      if (!loadMore) {
        _contractors = data;
        final endIndex = (_currentPage * _itemsPerPage).clamp(
          0,
          _contractors.length,
        );
        _displayedContractors = _contractors.sublist(0, endIndex);
        _hasMore = endIndex < _contractors.length;
      } else {
        _currentPage++;
        final endIndex = (_currentPage * _itemsPerPage).clamp(
          0,
          _contractors.length,
        );
        _displayedContractors = _contractors.sublist(0, endIndex);
        _hasMore = endIndex < _contractors.length;
      }

      setState(() {
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

  void _loadMoreContractors() {
    if (!_isLoadingMore && _hasMore) {
      _load(loadMore: true);
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
      // Silenciar errores para no bloquear la UI
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

  Future<void> _delete(String id, String legalName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.confirmDeleteTitle),
            content: Text(AppStrings.confirmDeleteMessage(legalName)),
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
        await _service.deleteContractor(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contratista eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          _load();
        } // Recargar lista
      } catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  void _editContractor(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractorEditScreen(contractorId: id),
      ),
    ).then((_) => _load());
  }

  void _viewContractor(String id) {
    final contractor = _displayedContractors.firstWhere(
      (c) => c['id'].toString() == id,
      orElse: () => {},
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles del Contratista'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', contractor['id']?.toString()),
                  _buildDetailRow(
                    'Razón Social',
                    contractor['legal_name']?.toString(),
                  ),
                  _buildDetailRow('RIF', contractor['rif']?.toString()),
                  _buildDetailRow('Correo', contractor['email']?.toString()),
                  _buildDetailRow('Teléfono', contractor['phone']?.toString()),
                  _buildDetailRow(
                    'Dirección',
                    contractor['address']?.toString(),
                  ),
                  _buildDetailRow('Franquicia', _getFranchiseName(contractor)),
                  _buildDetailRow(
                    'Usuarios',
                    (contractor['users'] is List
                            ? contractor['users'].length
                            : 0)
                        .toString(),
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

  String _getFranchiseName(Map<String, dynamic> c) {
    final dynamic fobj = c['franchise'];
    if (fobj is Map) {
      final dynamic name = fobj['branch_office'] ?? fobj['name'];
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }

    final dynamic fidDyn = c['franchise_id'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Gestión de Contratistas',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isLoading && _displayedContractors.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _load(isRefreshing: true),
              tooltip: AppStrings.refresh,
            ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContractorCreateScreen(),
                ),
              ).then((_) => _load());
            },
            tooltip: 'Agregar contratista',
          ),
        ],
        elevation: 4,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _displayedContractors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando contratistas...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_displayedContractors.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTable();
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
            'Error al cargar contratistas',
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
          const Icon(Icons.business, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No hay contratistas registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Crea el primer contratista para comenzar',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContractorCreateScreen(),
                ),
              ).then((_) => _load());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Crear primer contratista',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    // Preparamos los datos para AdaptiveDataView
    final formattedRows =
        _displayedContractors.map((c) {
          final id = c['id']?.toString() ?? '';
          final users = (c['users'] is List) ? c['users'] as List : const [];

          return {
            'id': id,
            'ID': id,
            'Razón Social':
                (c['legal_name'] ?? AppStrings.notAvailable).toString(),
            'RIF': (c['rif'] ?? AppStrings.notAvailable).toString(),
            'Correo': (c['email'] ?? AppStrings.notAvailable).toString(),
            'Teléfono': (c['phone'] ?? AppStrings.notAvailable).toString(),
            'Franquicia': _getFranchiseName(c),
            'Usuarios': users.length.toString(),
            'Dirección': (c['address'] ?? '').toString(),
          };
        }).toList();

    return RefreshIndicator(
      onRefresh: () => _load(isRefreshing: true),
      child: AdaptiveDataView(
        // CONFIGURACIÓN DE COLUMNAS
        columns: const [
          'ID',
          'Razón Social',
          'RIF',
          'Correo',
          'Teléfono',
          'Franquicia',
          'Usuarios',
          'Acciones',
        ],
        rows: formattedRows,
        title: 'Lista de Contratistas',

        // ACCIONES CRUD COMPLETAS
        onView: _viewContractor,
        onEdit: _editContractor,
        onDelete: (id) {
          final contractor = _displayedContractors.firstWhere(
            (c) => c['id'].toString() == id,
            orElse: () => {},
          );
          final legalName = (contractor['legal_name'] ?? '').toString();
          _delete(id, legalName.isNotEmpty ? legalName : 'contratista');
        },

        // INFINITE SCROLL
        onLoadMore: _loadMoreContractors,
        isLoadingMore: _isLoadingMore,
        hasMore: _hasMore,

        // LABELS MEJORADOS
        columnLabels: const {
          'ID': 'ID',
          'Razón Social': 'Razón Social',
          'RIF': 'RIF',
          'Correo': 'Correo Electrónico',
          'Teléfono': 'Teléfono',
          'Franquicia': 'Franquicia',
          'Usuarios': 'N° Usuarios',
          'Acciones': 'Acciones',
        },
      ),
    );
  }
}
