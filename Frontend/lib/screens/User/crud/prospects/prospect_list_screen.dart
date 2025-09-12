import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProspects();
    _loadFranchises();
  }

  Future<void> _loadProspects({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final prospects = await _prospectService.getAllProspects();
      setState(() {
        _prospects =
            prospects
                .map((prospect) => prospect as Map<String, dynamic>)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar(e);
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
        _loadProspects();
      } catch (e) {
        _showErrorSnackBar(e);
      }
    }
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
          if (!_isLoading && _prospects.isNotEmpty)
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_prospects.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProspectList();
  }

  Widget _buildErrorState() {
    return Center(
      child: ListView(
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

  Widget _buildProspectList() {
    return RefreshIndicator(
      onRefresh: () => _loadProspects(isRefreshing: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de búsqueda (opcional)
            // _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: DataTableCustom(
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
                rows:
                    _prospects.map((prospect) {
                      return {
                        'id': prospect['id'],
                        'ID': prospect['id'].toString(),
                        'Nombre': _formatName(prospect),
                        'Documento':
                            prospect['document']?.toString() ??
                            AppStrings.notAvailable,
                        'Correo': prospect['email'] ?? AppStrings.notAvailable,
                        'Teléfono':
                            prospect['phone'] ?? AppStrings.notAvailable,
                        'Franquicia': _getFranchiseName(prospect),
                        'Plan': prospect['plan'] ?? AppStrings.notAvailable,
                        'Estado':
                            prospect['status_red']?.toString() ??
                            AppStrings.notAvailable,
                      };
                    }).toList(),
                onEdit: (id) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProspectEditScreen(prospectId: id),
                    ),
                  ).then((_) => _loadProspects());
                },
                onDelete: (id) {
                  final prospect = _prospects.firstWhere(
                    (p) => p['id'].toString() == id,
                    orElse: () => {},
                  );
                  final name = _formatName(prospect);
                  _deleteProspect(id, name);
                },
              ),
            ),
          ],
        ),
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

  //Widget _buildSearchBar() {
  //  return TextField(
  //    decoration: InputDecoration(
  //      hintText: AppStrings.searchProspects,
  //      prefixIcon: const Icon(Icons.search),
  //      border: OutlineInputBorder(
  //        borderRadius: BorderRadius.circular(8),
  //      ),
  //    ),
  //  onSubmitted: (value) => _filterProspects(value),
  //  );
  //}
}
