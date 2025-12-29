import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/services/others/role_service.dart';
import 'package:vnet_agenda/widgets/adaptive_data_view.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_create_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserServices _userService = UserServices();
  final FranchiseService _franchiseService = FranchiseService();
  final RoleService _roleService = RoleService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Map<int, String> _franchiseNames = {};
  final Map<int, String> _roleNames = {};
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Variables para infinite scroll
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  final int _itemsPerPage = 10;
  List<Map<String, dynamic>> _displayedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadFranchises();
    _loadRoles();
  }

  Future<void> _loadUsers({
    bool isRefreshing = false,
    bool loadMore = false,
  }) async {
    if (!isRefreshing && !loadMore) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _currentPage = 1;
        _displayedUsers = [];
      });
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
      await Future.delayed(const Duration(milliseconds: 500)); // Simula carga
    }

    try {
      final users = await _userService.getAllUser();

      // Filtrar usuario actual
      final currentId = await _storage.read(key: 'user_id');
      final filtered =
          users.whereType<Map<String, dynamic>>().where((u) {
            if (currentId == null || currentId.isEmpty) return true;
            final userId = (u['id'] ?? u['user_id'])?.toString() ?? '';
            return userId != currentId;
          }).toList();

      setState(() {
        _users = filtered;

        // Simular paginación para infinite scroll
        if (!loadMore) {
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _users.length,
          );
          _displayedUsers = _users.sublist(0, endIndex);
          _hasMore = endIndex < _users.length;
        } else {
          _currentPage++;
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _users.length,
          );
          _displayedUsers = _users.sublist(0, endIndex);
          _hasMore = endIndex < _users.length;
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

  void _loadMoreUsers() {
    if (!_isLoadingMore && _hasMore) {
      _loadUsers(loadMore: true);
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

  Future<void> _loadRoles() async {
    try {
      final roles = await _roleService.getAllRole();
      setState(() {
        for (final role in roles) {
          final dynamic id = role['id'];
          int? key;
          if (id is int) {
            key = id;
          } else if (id is String) {
            key = int.tryParse(id);
          }

          if (key != null) {
            final String roleName =
                (role['name'] ?? role['role_name'] ?? 'Rol sin nombre')
                    .toString();
            _roleNames[key] = roleName;
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

  Future<void> _deleteUser(String id, String name) async {
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
        await _userService.deleteUser(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        } // Recargar lista
      } catch (e) {
        _showErrorSnackBar(e);
      }
    }
  }

  void _editUser(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserEditScreen(userId: id)),
    ).then((_) => _loadUsers());
  }

  void _viewUser(String id) {
    final user = _displayedUsers.firstWhere(
      (u) => u['id'].toString() == id,
      orElse: () => {},
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles del Usuario'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', user['id']?.toString()),
                  _buildDetailRow('Nombre', _formatName(user)),
                  _buildDetailRow('Correo', user['email']?.toString()),
                  _buildDetailRow('Documento', user['document']?.toString()),
                  _buildDetailRow('Teléfono', user['phone']?.toString()),
                  _buildDetailRow('Franquicia', _getFranchiseName(user)),
                  _buildDetailRow('Rol', _getRoleName(user)),
                  if (user['created_at'] != null)
                    _buildDetailRow('Creado', user['created_at']?.toString()),
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

  String _formatName(Map<String, dynamic> user) {
    final firstName = user['name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    return (user['email'] ?? AppStrings.anonymous).toString();
  }

  String _getFranchiseName(Map<String, dynamic> user) {
    final dynamic fobj = user['franchise'];
    if (fobj is Map) {
      final dynamic name = fobj['branch_office'] ?? fobj['name'];
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }

    final dynamic fidDyn = user['franchise_id'];
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

  String _getRoleName(Map<String, dynamic> user) {
    final dynamic robj = user['role'];
    if (robj is Map) {
      final dynamic name = robj['name'] ?? robj['role_name'];
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }
    final dynamic dynRole = user['role_id'];
    int? fix;
    if (dynRole is int) {
      fix = dynRole;
    } else if (dynRole is String) {
      fix = int.tryParse(dynRole);
    }
    if (fix != null) {
      final lookup = _roleNames[fix];
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
          'Gestión de Usuarios',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isLoading && _displayedUsers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadUsers(isRefreshing: true),
              tooltip: AppStrings.refresh,
            ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserCreateScreen(),
                ),
              ).then((_) => _loadUsers());
            },
            tooltip: 'Agregar usuario',
          ),
        ],
        elevation: 4,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _displayedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando usuarios...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_displayedUsers.isEmpty) {
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
            'Error al cargar usuarios',
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
            onPressed: () => _loadUsers(),
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
          const Icon(Icons.people, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No hay usuarios registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Crea el primer usuario para comenzar',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserCreateScreen(),
                ),
              ).then((_) => _loadUsers());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Crear primer usuario',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveDataView() {
    final formattedRows =
        _displayedUsers.map((user) {
          return {
            'id': user['id']?.toString() ?? '',
            'ID': user['id']?.toString() ?? '',
            'Nombre': _formatName(user),
            'Documento':
                (user['document'] ?? AppStrings.notAvailable).toString(),
            'Correo': (user['email'] ?? AppStrings.notAvailable).toString(),
            'Teléfono': (user['phone'] ?? AppStrings.notAvailable).toString(),
            'Franquicia': _getFranchiseName(user),
            'Rol': _getRoleName(user),
            'Acciones': '',
          };
        }).toList();

    return AdaptiveDataView(
      columns: const [
        'ID',
        'Nombre',
        'Documento',
        'Correo',
        'Teléfono',
        'Franquicia',
        'Rol',
        'Acciones',
      ],
      rows: formattedRows,
      title: 'Lista de Usuarios',

      // CRUD
      onView: _viewUser,
      onEdit: _editUser,
      onDelete: (id) {
        final user = _displayedUsers.firstWhere(
          (u) => u['id'].toString() == id,
          orElse: () => {},
        );
        final name = _formatName(user);
        _deleteUser(id, name.isNotEmpty ? name : 'usuario');
      },

      onLoadMore: _loadMoreUsers,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,

      columnLabels: const {
        'ID': 'ID',
        'Nombre': 'Nombre Completo',
        'Documento': 'Documento de Identidad',
        'Correo': 'Correo Electrónico',
        'Teléfono': 'Teléfono',
        'Franquicia': 'Franquicia',
        'Rol': 'Rol de Usuario',
        'Acciones': 'Acciones',
      },
    );
  }
}
