import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vnet_agenda/widgets/supervisor_drawer.dart';

class HomeSupervisorScreen extends StatefulWidget {
  const HomeSupervisorScreen({super.key});

  @override
  State<HomeSupervisorScreen> createState() => _HomeSupervisorScreenState();
}

final Logger _logger = Logger();

class _HomeSupervisorScreenState extends State<HomeSupervisorScreen> {
  final ProspectService _prospectService = ProspectService();
  final MeetingService _meetingService = MeetingService();

  List<Map<String, dynamic>> _meetings = [];
  bool _initialLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Loading por fila (id prospecto -> cargando)
  final Map<String, bool> _rowLoading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _initialLoading = true;
        _errorMessage = '';
        _hasError = false;
      });
    }

    try {
      final data = await _meetingService.getAllMeetingEnd();
      _logger.d('Citas finalizadas: $data');
      if (!mounted) return;

      setState(() {
        _meetings = data;
        _initialLoading = false;
      });
    } catch (e, st) {
      _logger.e('Error cargando reuniones', error: e, stackTrace: st);
      if (!mounted) return;

      setState(() {
        _initialLoading = false;
        _errorMessage = e.toString();
        _hasError = true;
      });
      _showErrorSnackBar(e);
    }
  }

  void _showErrorSnackBar(dynamic error) {
    String message;
    final text = error.toString();

    if (text.contains('Network')) {
      message = AppStrings.networkError;
    } else if (text.contains('401')) {
      message = AppStrings.unauthorizedError;
    } else if (text.contains('404')) {
      message = AppStrings.notFoundError;
    } else {
      message = AppStrings.genericError;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Recargar',
          textColor: Colors.white,
          onPressed: () => _load(isRefreshing: true),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isConnectedStatus(String statusRaw) {
    final s = (statusRaw).trim().toLowerCase();
    return s == 'conectado' ||
        s == 'activo' ||
        s == 'connected' ||
        s == 'active';
  }

  Future<void> _statusChange(String id) async {
    _logger.d('Activando cliente $id');

    setState(() {
      _rowLoading[id] = true;
    });

    try {
      await _prospectService.changeProspect(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conexión establecida'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _load(isRefreshing: true);
    } catch (e, st) {
      _logger.e(
        'Error cambiando estado del prospecto $id',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _rowLoading.remove(id);
      });
    }
  }

  void _confirmConnectDialog(String id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.power_settings_new, color: Colors.blue),
                SizedBox(width: 8),
                Text('Confirmar activación'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Deseas activar la conexión para este cliente?'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID prospecto: $id',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _statusChange(id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sí, activar'),
              ),
            ],
          ),
    );
  }

  void _showContractDetails(Map<String, dynamic> meeting) {
    final id = (meeting['id_prospect'] ?? '').toString();
    final status = (meeting['status'] ?? '').toString();
    final conectado = _isConnectedStatus(status);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Contrato ${meeting['nro_contract'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: conectado ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conectado
                          ? 'Conectado'
                          : (status.isEmpty ? 'Pendiente' : status),
                      style: TextStyle(
                        color:
                            conectado ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Técnico', meeting['tecnico']),
              _detailRow('Contratista', meeting['contratista']),
              _detailRow('Usuario PPPoE', meeting['usuario_ppoe']),
              _detailRow('Password PPPoE', meeting['password_ppoe']),
              _detailRow('ID Prospecto', id),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          conectado ? null : () => _confirmConnectDialog(id),
                      icon: const Icon(Icons.power_settings_new),
                      label: Text(conectado ? 'Ya conectado' : 'Conectar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final text = (value ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text.isEmpty ? '-' : text,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta deslizante (nativa con Dismissible para acciones laterales)
  Widget _buildContractTile(Map<String, dynamic> meeting) {
    final String id = (meeting['id_prospect'] ?? '').toString();
    final String nroContract = (meeting['nro_contract'] ?? '').toString();
    final String status = (meeting['status'] ?? '').toString();
    final String tecnico = (meeting['tecnico'] ?? '').toString();
    final String contratista = (meeting['contratista'] ?? '').toString();
    final bool conectado = _isConnectedStatus(status);
    final bool busy = _rowLoading[id] == true;

    return Dismissible(
      key: ValueKey('contract-$id-$nroContract'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // En vez de eliminar, usamos el gesto para mostrar acciones y regresamos false
        // Mostramos un snackbar con acciones rápidas
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.tune, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Acciones para contrato $nroContract')),
                TextButton(
                  onPressed:
                      busy || conectado
                          ? null
                          : () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            _confirmConnectDialog(id);
                          },
                  child: Text(
                    conectado ? 'Conectado' : 'Conectar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _showContractDetails(meeting);
                  },
                  child: const Text(
                    'Detalles',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.tune, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Acciones',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => _showContractDetails(meeting),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contrato $nroContract',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.engineering,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tecnico.isEmpty ? '-' : tecnico,
                            style: TextStyle(color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            contratista.isEmpty ? '-' : contratista,
                            style: TextStyle(color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: conectado ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (busy)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        conectado ? Icons.check_circle : Icons.wifi_tethering,
                        size: 16,
                        color:
                            conectado ? Colors.green[800] : Colors.orange[800],
                      ),
                    const SizedBox(width: 6),
                    Text(
                      conectado ? 'Conectado' : 'Pendiente',
                      style: TextStyle(
                        color:
                            conectado ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractList() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Ocurrió un error al cargar los datos',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _load(isRefreshing: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_meetings.isEmpty) {
      return const Center(child: Text('No hay contratos para mostrar'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(isRefreshing: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _meetings.length,
        itemBuilder: (ctx, index) => _buildContractTile(_meetings[index]),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Supervisor'),
      backgroundColor: AppColors.primaryColor,
      actions: [
        IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _load(isRefreshing: true),
            tooltip: 'Recargar',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, color: Colors.white),
          tooltip: 'Mi cuenta',
          onSelected: (value) async {
            const storage = FlutterSecureStorage();
            final userId = await storage.read(key: 'user_id');
            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo obtener el usuario actual'),
                  ),
                );
              }
              return;
            }

            if (value == 'edit') {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserEditScreen(userId: userId),
                  ),
                );
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Eliminar mi cuenta'),
                      content: const Text(
                        'Esta acción es irreversible. ¿Desea continuar?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                try {
                  await UserServices().deleteUser(userId);
                  await AuthService().logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const InitSelectUserScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            }
          },
          itemBuilder:
              (ctx) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar mi perfil')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar mi cuenta'),
                ),
              ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Desea cerrar la sesión actual?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Salir',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
            if (confirmed == true) {
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const InitSelectUserScreen(),
                  ),
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
      centerTitle: true,
      elevation: 4,
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.dashboard,
                size: 28,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Contratos finalizados",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildContractList()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      drawer: const CustomSupervisorDrawer(),
      body: _buildWelcomeContent(),
    );
  }
}
