import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:vnet_agenda/widgets/adaptive_data_view.dart'; // ← CAMBIO IMPORT
import 'package:vnet_agenda/screens/User/crud/order/order_completion_screen.dart';
import 'package:vnet_agenda/services/crud/order_service.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

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

  // Variables para infinite scroll
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  final int _itemsPerPage = 10;
  List<Map<String, dynamic>> _displayedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({
    bool isRefreshing = false,
    bool loadMore = false,
  }) async {
    if (!isRefreshing && !loadMore) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _currentPage = 1;
        _displayedOrders = [];
      });
    }

    if (loadMore) {
      setState(() => _isLoadingMore = true);
      await Future.delayed(const Duration(milliseconds: 500)); // Simula carga
    }

    try {
      final orders = await _orderService.getAllOrders();
      _logger.d('Órdenes obtenidas: ${orders.length}');

      setState(() {
        _orders = orders;

        // Simular paginación para infinite scroll
        if (!loadMore) {
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _orders.length,
          );
          _displayedOrders = _orders.sublist(0, endIndex);
          _hasMore = endIndex < _orders.length;
        } else {
          _currentPage++;
          final endIndex = (_currentPage * _itemsPerPage).clamp(
            0,
            _orders.length,
          );
          _displayedOrders = _orders.sublist(0, endIndex);
          _hasMore = endIndex < _orders.length;
        }

        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = 'Error al cargar las órdenes: $e';
      });
      _showErrorSnackbar(e);
    }
  }

  void _loadMoreOrders() {
    if (!_isLoadingMore && _hasMore) {
      _loadOrders(loadMore: true);
    }
  }

  // Future<void> _deleteOrder(String orderId) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text(AppStrings.confirmDeleteTitle),
  //           content: Text(AppStrings.confirmDeleteMessage('la orden')),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, false),
  //               child: const Text(AppStrings.cancel),
  //             ),
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, true),
  //               child: const Text(
  //                 AppStrings.delete,
  //                 style: TextStyle(color: Colors.red),
  //               ),
  //             ),
  //           ],
  //         ),
  //   );

  //   if (confirmed == true) {
  //     try {
  //       await _orderService.deleteOrder(orderId);
  //       setState(() {
  //         _orders.removeWhere((order) => order['id'].toString() == orderId);
  //         _displayedOrders.removeWhere(
  //           (order) => order['id'].toString() == orderId,
  //         );
  //       });
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Orden eliminada exitosamente')),
  //         );
  //       }
  //     } catch (e) {
  //       _showErrorSnackbar(e);
  //     }
  //   }
  // }

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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderListScreen()),
    ).then((_) => _loadOrders());
  }

  // void _editOrder(String id) {
  //   // Buscar la orden completa para pasar todos los datos
  //   final order = _displayedOrders.firstWhere(
  //     (order) => order['id'].toString() == id,
  //     orElse: () => {},
  //   );
  //   _logger.d('Datos Orden para editar: $order');

  //   if (order.isEmpty) {
  //     _showErrorSnackbar('Orden no encontrada');
  //     return;
  //   }

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (context) => OrderEditScreen(
  //             key: ValueKey('order_edit_$id'),
  //             orderId: id,
  //             userId: order['user_id']?.toString() ?? '',
  //             prospectId: order['prospect_aradial_id']?.toString() ?? '',
  //             meetingId: order['id_meeting']?.toString() ?? '',
  //           ),
  //     ),
  //   ).then((_) => _loadOrders());
  // }

  void _viewOrder(String id) {
    final order = _displayedOrders.firstWhere(
      (order) => order['id'].toString() == id,
      orElse: () => {},
    );

    if (order.isEmpty) {
      _showErrorSnackbar('Orden no encontrada');
      return;
    }

    // Mostrar detalles en un diálogo
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles de la Orden'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', order['id']?.toString()),
                  _buildDetailRow('Cliente', _getClientName(order)),
                  _buildDetailRow('Técnico', _getTechnicianName(order)),
                  _buildDetailRow(
                    'Fecha Cita',
                    _formatDateTime(
                      order['meeting']?['date_time1']?.toString(),
                    ),
                  ),
                  _buildDetailRow(
                    'Plan',
                    order['meeting']?['prospect_aradial']?['plan']?.toString(),
                  ),
                  _buildDetailRow(
                    'Estado',
                    _formatStatus(
                      order['meeting']?['status']?.toString() ?? '',
                    ),
                  ),
                  _buildDetailRow('Franquicia', _getFranchiseName(order)),
                  _buildDetailRow(
                    'Observaciones',
                    order['observations']?.toString(),
                  ),
                  if (order['created_at'] != null)
                    _buildDetailRow(
                      'Creada',
                      _formatDateTime(order['created_at']?.toString()),
                    ),
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
                      builder: (context) => OrderCompletionScreen(orderId: id),
                    ),
                  );
                },
                child: const Text('Completar Orden'),
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
              value ?? 'No disponible',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _getClientName(Map<String, dynamic> order) {
    final prospect = order['meeting']?['prospect_aradial'] ?? {};
    final clientName =
        '${prospect['name'] ?? ''} ${prospect['last_name'] ?? ''}'.trim();
    return clientName.isNotEmpty ? clientName : 'Cliente no disponible';
  }

  String _getTechnicianName(Map<String, dynamic> order) {
    final user = order['user'] ?? {};
    final technicianName =
        '${user['name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    return technicianName.isNotEmpty ? technicianName : 'Técnico no asignado';
  }

  String _getFranchiseName(Map<String, dynamic> order) {
    final franchise = order['meeting']?['prospect_aradial']?['franchise'] ?? {};
    return franchise['branch_office'] ?? franchise['name'] ?? 'No especificada';
  }

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
          if (!_isLoading && _displayedOrders.isNotEmpty)
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

  Widget _buildContent() {
    if (_isLoading && _displayedOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando órdenes...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_displayedOrders.isEmpty) {
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

  Widget _buildAdaptiveDataView() {
    // Preparamos los datos para AdaptiveDataView
    final formattedRows =
        _displayedOrders.map((order) {
          return {
            'id': order['id']?.toString() ?? '',
            'ID': '#${order['id']?.toString() ?? ''}',
            'Cliente': _getClientName(order),
            'Técnico': _getTechnicianName(order),
            'Fecha Cita': _formatDateTime(
              order['meeting']?['date_time1']?.toString(),
            ),
            'Plan':
                order['meeting']?['prospect_aradial']?['plan']?.toString() ??
                'No especificado',
            'Estado': _formatStatus(
              order['meeting']?['status']?.toString() ?? '',
            ),
            'Acciones': '', // Columna vacía para acciones
          };
        }).toList();

    return AdaptiveDataView(
      // CONFIGURACIÓN DE COLUMNAS
      columns: const [
        'ID',
        'Cliente',
        'Técnico',
        'Fecha Cita',
        'Plan',
        'Estado',
        'Acciones',
      ],
      rows: formattedRows,
      title: 'Órdenes de Instalación',

      // ACCIONES CRUD
      onView: _viewOrder,
      onEdit: null,
      onDelete: null,

      // INFINITE SCROLL
      onLoadMore: _loadMoreOrders,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,

      // LABELS MEJORADOS
      columnLabels: const {
        'ID': 'N° Orden',
        'Cliente': 'Nombre del Cliente',
        'Técnico': 'Técnico Asignado',
        'Fecha Cita': 'Fecha y Hora de Cita',
        'Plan': 'Plan Contratado',
        'Estado': 'Estado de la Orden',
        'Acciones': 'Acciones',
      },
    );
  }
}
