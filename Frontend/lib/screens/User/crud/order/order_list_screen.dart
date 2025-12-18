import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_completion_screen.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_edit_screen.dart';
import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/widgets/data_table_custom.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderService _orderService = OrderService();
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() => _isLoading = true);
    }

    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final orders = await _orderService.getAllOrders();
      _logger.d('Ordenes obtenidas: $orders');
      setState(() => _orders = orders);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error al cargar las órdenes: $e';
      });
    } finally {
      if (!isRefreshing) {
        setState(() => _isLoading = false);
      }
    }
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
        await _orderService.deleteOrder(orderId);
        setState(() {
          _orders.removeWhere((order) => order['id'].toString() == orderId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden eliminada exitosamente')),
        );
      } catch (e) {
        _showErrorSnackbar(e);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Gestión de Órdenes de Instalación',
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
            onPressed: _navigateToCreateOrder,
            tooltip: 'Agregar Orden',
          ),
        ],
        elevation: 4,
      ),
      body: _buildContent(),
    );
  }

  void _navigateToCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderListScreen()),
    ).then((_) => _loadOrders());
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar órdenes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadOrders(),
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
          const Icon(Icons.assignment, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No hay órdenes registradas',
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
            onPressed: _navigateToCreateOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Crear primera orden',
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
            // Contador de órdenes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${_orders.length} orden(es)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: DataTableCustom(
                columns: const [
                  'ID',
                  'Cliente',
                  'Técnico',
                  'Fecha Cita',
                  'Plan',
                  'Estado',
                  'Acciones',
                ],
                rows: _orders.map(_buildOrderRow).toList(),
                onEdit: (id) => _navigateToEditOrder(id),
                onDelete: (id) => _deleteOrder(id),
                onView:
                    (id) => _navigateToViewOrder(
                      id,
                    ), // Si necesitas vista de detalles
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO OPTIMIZADO - Extrae datos directamente de la estructura anidada
  Map<String, dynamic> _buildOrderRow(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? 'N/A';

    // ✅ DATOS DEL PROSPECTO (desde meeting → prospect_aradial)
    final prospect = order['meeting']?['prospect_aradial'] ?? {};
    final clientName =
        '${prospect['name'] ?? ''} ${prospect['last_name'] ?? ''}'.trim();
    final plan = prospect['plan']?.toString() ?? 'No especificado';

    // ✅ DATOS DEL TÉCNICO (desde user)
    final user = order['user'] ?? {};
    final technicianName =
        '${user['name'] ?? ''} ${user['last_name'] ?? ''}'.trim();

    // ✅ DATOS DE LA CITA (desde meeting)
    final meeting = order['meeting'] ?? {};
    final appointmentDate = _formatDateTime(meeting['date_time1']?.toString());
    final status = meeting['status']?.toString() ?? 'Desconocido';

    return {
      'id': id,
      'ID': '#$id',
      'Cliente': clientName.isNotEmpty ? clientName : 'Cliente no disponible',
      'Técnico':
          technicianName.isNotEmpty ? technicianName : 'Técnico no asignado',
      'Fecha Cita': appointmentDate,
      'Plan': plan,
      'Estado': _formatStatus(status),
      // Datos adicionales para acciones
      '_user_id': order['user_id']?.toString(),
      '_prospect_id': order['prospect_aradial_id']?.toString(),
      '_meeting_id': order['id_meeting']?.toString(),
      '_full_order': order, // Guardar orden completa por si necesitas más datos
    };
  }

  // ✅ FORMATEAR FECHA
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'Fecha no disponible';
    }

    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // ✅ FORMATEAR ESTADO CON EMOJIS Y COLORES
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'finalizada':
        return '✅ Finalizada';
      case 'pendiente':
        return '⏳ Pendiente';
      case 'en_progreso':
        return '🔄 En progreso';
      case 'cancelada':
        return '❌ Cancelada';
      default:
        return '❓ $status';
    }
  }

  // ✅ NAVEGACIÓN OPTIMIZADA PARA EDITAR
  void _navigateToEditOrder(String? id) {
    if (id == null) return;

    // Buscar la orden completa para pasar todos los datos
    final order = _orders.firstWhere(
      (order) => order['id'].toString() == id,
      orElse: () => {},
    );
    _logger.d('Datos Orden: $order');

    if (order.isEmpty) {
      _showErrorSnackbar('Orden no encontrada');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OrderEditScreen(
              key: ValueKey('order_edit_$id'),
              orderId: id,
              userId: order['user_id']?.toString() ?? '',
              prospectId: order['prospect_aradial_id']?.toString() ?? '',
              meetingId: order['id_meeting']?.toString() ?? '',
            ),
      ),
    ).then((_) => _loadOrders());
  }

  // ✅ NAVEGACIÓN PARA VER DETALLES (si necesitas)
  void _navigateToViewOrder(String? id) {
    if (id == null) return;

    final order = _orders.firstWhere(
      (order) => order['id'].toString() == id,
      orElse: () => {},
    );

    if (order.isEmpty) {
      _showErrorSnackbar('Orden no encontrada');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderCompletionScreen(orderId: id),
      ),
    );
  }
}
