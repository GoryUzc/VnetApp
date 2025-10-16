import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_edit_screen.dart';
import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _formatKey = GlobalKey<FormState>();
  // Servicios
  final OrderService _orderServices = OrderService();
  final UserServices _userServices = UserServices();
  final ProspectService _prospectService = ProspectService();

  // Variables
  String? _prospectName = '';
  String? _userName = '';
  String? _userId;
  String? _prospectId;
  String? _meetingId;

  // Lista de órdenes
  List<Map<String, dynamic>> _orders = [];

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMesage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadProspect();
    _loadUsers();
  }

  Future _loadOrders({bool isRefreshing = false}) async {
    if (isRefreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMesage = '';
      });
    }
    try {
      final orders = await _orderServices.getAllOrders();
      setState(() {
        _orders = orders;
        _userId = orders.isNotEmpty ? orders[0]['user_id'] : null;
        _prospectId =
            orders.isNotEmpty ? orders[0]['prospect_aradial_id'] : null;
        _meetingId = orders.isNotEmpty ? orders[0]['id_meeting'] : null;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMesage = 'Error al cargar las ordenes: $e';
      });
    } finally {
      if (isRefreshing) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future _loadUsers() async {
    try {
      final users = await _userServices.getAllUser();
      setState(() {
        _userName =
            users.isNotEmpty
                ? users.firstWhere(
                  (user) => user['id'].toString() == _userId,
                  orElse: () => {'name': 'Desconocido'},
                )['name']
                : 'Desconocido';
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMesage = 'Error al cargar los usuarios: $e';
      });
    }
  }

  Future _loadProspect() async {
    try {
      final prospects = await _prospectService.getAllProspects();
      setState(() {
        _prospectName =
            prospects.isNotEmpty
                ? prospects.firstWhere(
                  (prospect) => prospect['id'].toString() == _prospectId,
                  orElse: () => {'name': 'Desconocido'},
                )['name']
                : 'Desconocido';
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMesage = 'Error al cargar los prospectos: $e';
      });
    }
  }

  void _showErrorSnackbar(dynamic error) {
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

  Future<void> _deleteOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.confirmDeleteTitle),
            content: Text(AppStrings.confirmDeleteMessage('la orden')),
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
        await _orderServices.deleteOrder(orderId);
        setState(() {
          _orders.removeWhere((order) => order['id'] == orderId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden eliminada exitosamente')),
        );
      } catch (e) {
        _showErrorSnackbar(e);
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
          'Gestión de Ordenes de instalacion',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isLoading && _orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadOrders(isRefreshing: true),
              tooltip: AppStrings.refresh,
            ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const OrderListScreen(), //Cambiar por pantalla para crear
                ),
              ).then((_) => _loadUsers());
            },
            tooltip: 'Agregar Orden',
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

    if (_orders.isEmpty) {
      return _buildEmptyState();
    }

    return _buildOrdersTable();
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
            _errorMesage,
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
            'No hay ordenes registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Crea la primera orden para comenzar',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const OrderListScreen(), //Cambiar por pantalla para crear
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

  Widget _buildOrdersTable() {
    return RefreshIndicator(
      onRefresh: () => _loadOrders(isRefreshing: true),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: DataTableCustom(
                columns: const [
                  'ID',
                  'Prospecto',
                  'Tecnico',
                  'ID Cita',
                  'Observaciones',
                  'Acciones',
                ],
                rows:
                    _orders.map((u) {
                      final id = u['id'] ?? '';
                      return {
                        'id': id,
                        'ID': id?.toString(),
                        'Prospecto': _prospectName,
                        'Tecnico': _userName,
                        'ID Cita': (u['id_meeting'] ?? ''),
                        'Observaciones': (u['detalles_instalacion'] ?? ''),
                      };
                    }).toList(),
                onEdit: (id) {
                  // Navegar a la pantalla de edición
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OrderEditScreen(
                            key: _formatKey, // Usar la clave definida
                            userId: _userId,
                            prospectId: _prospectId,
                            meetingId: _meetingId, // Pasar el userId
                          ),
                    ),
                  ).then((_) => _loadOrders());
                },
                onDelete: (id) => _deleteOrder(id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
