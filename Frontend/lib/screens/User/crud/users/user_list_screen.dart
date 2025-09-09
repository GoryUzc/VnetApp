import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/services/others/role_service.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';
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

  final Map<int, String> _franchiseNames = {};
  final Map<int, String> _roleNames = {};
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadFranchises();
    _loadRoles();
  }

  Future<void> _loadUsers({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final users = await _userService.getAllUser();
      const storage = FlutterSecureStorage();
      final currentId = await storage.read(key: 'user_id');
      final list = users.whereType<Map<String, dynamic>>().toList();
      final filtered =
          (currentId == null || currentId.isEmpty)
              ? list
              : list
                  .where(
                    (u) =>
                        ((u['id'] ?? u['user_id'])?.toString() ?? '') !=
                        currentId,
                  )
                  .toList();
      setState(() {
        _users = filtered;
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
            // ✅ Guardamos el NOMBRE del rol, no el ID
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
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
          'Gestión de Usuarios',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isLoading && _users.isNotEmpty)
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_users.isEmpty) {
      return _buildEmptyState();
    }

    return _buildUserTable();
  }

  Widget _buildErrorState() {
    return Center(
      child: ListView(
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

  Widget _buildUserTable() {
    return RefreshIndicator(
      onRefresh: () => _loadUsers(isRefreshing: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                  'Rol',
                  'Acciones',
                ],
                rows:
                    _users.map((u) {
                      final id = u['id'];
                      return {
                        'id': id,
                        'ID': id?.toString() ?? '',
                        'Nombre': _formatName(u),
                        'Documento':
                            (u['document'] ?? AppStrings.notAvailable)
                                .toString(),
                        'Correo':
                            (u['email'] ?? AppStrings.notAvailable).toString(),
                        'Teléfono':
                            (u['phone'] ?? AppStrings.notAvailable).toString(),
                        'Franquicia': _getFranchiseName(u),
                        'Rol': _getRoleName(u),
                      };
                    }).toList(),
                onEdit: (id) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserEditScreen(userId: id),
                    ),
                  ).then((_) => _loadUsers());
                },
                onDelete: (id) {
                  final user = _users.firstWhere(
                    (p) => p['id'].toString() == id,
                    orElse: () => {},
                  );
                  final name = _formatName(user);
                  _deleteUser(id, name);
                },
              ),
            ),
          ],
        ),
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
    if (dynRole != null) {
      final lookup = _roleNames[fix];
      if (lookup != null && lookup.isNotEmpty) {
        return lookup;
      }
    }
    return AppStrings.notAvailable;
  }
}
