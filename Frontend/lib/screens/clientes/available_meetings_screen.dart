import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/screens/clientes/cancel_meeting_screen.dart';

class AvailableMeetingsScreen extends StatefulWidget {
  final String idProspect;
  const AvailableMeetingsScreen({super.key, required this.idProspect});

  @override
  State<AvailableMeetingsScreen> createState() =>
      _AvailableMeetingsScreenState();
}

final Logger _logger = Logger();

class _AvailableMeetingsScreenState extends State<AvailableMeetingsScreen> {
  final MeetingService _meetingService = MeetingService();

  List<Map<String, dynamic>> _meetings = [];
  bool _loading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _appBarRefreshing = false;
  String idM = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _loading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }
    try {
      // Debe devolver: { message: string, meetings: List<Map> }
      final resp = await _meetingService.getMeetingContractProspect(
        widget.idProspect,
      );

      final Map<String, dynamic>? respMap =
          resp is Map ? Map<String, dynamic>.from(resp as Map) : null;

      final List<dynamic> rawMeetings =
          (respMap != null && respMap['meetings'] is List)
              ? (respMap['meetings'] as List<dynamic>)
              : <dynamic>[];

      final normalized =
          rawMeetings.map<Map<String, dynamic>>((m) {
            final map = Map<String, dynamic>.from(m as Map);
            return {
              'nro_contract': (map['nro_contract'] ?? '').toString(),
              'tecnico': (map['tecnico'] ?? '').toString(),
              'contratista': (map['contratista'] ?? '').toString(),
              'status': (map['status'] ?? '').toString(),
              'fechaHora': map['fechaHora'],
              'id_meeting':
                  (map['id_meeting'] ?? map['id_meeting'] ?? map['id'] ?? '')
                      .toString(),
            };
          }).toList();

      if (!mounted) return;
      setState(() {
        _meetings = normalized;
        _loading = false;
      });
    } catch (e, st) {
      _logger.e('Error cargando citas disponibles', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = e.toString();
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
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: () => _load(isRefreshing: true),
        ),
      ),
    );
  }

  // Formato de fecha y hora desde ISO-8601 (fechaHora)
  String _formatFecha(dynamic fechaHora) {
    if (fechaHora == null) return '-';
    try {
      final dt = DateTime.parse(fechaHora.toString()).toLocal();
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return '-';
    }
  }

  String _formatHora(dynamic fechaHora) {
    if (fechaHora == null) return '-';
    try {
      final dt = DateTime.parse(fechaHora.toString()).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '-';
    }
  }

  // Card: solo muestra el número de contrato
  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final String nroContract = (meeting['nro_contract'] ?? '').toString();

    return InkWell(
      onTap: () => _showDetailsSheet(meeting),
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
              child: const Icon(Icons.receipt_long, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Contrato $nroContract',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  // Bottom sheet con datos generales y botón de cancelación
  void _showDetailsSheet(Map<String, dynamic> meeting) {
    final String nroContract = (meeting['nro_contract'] ?? '').toString();
    final String tecnico = (meeting['tecnico'] ?? '').toString();
    final String contratista = (meeting['contratista'] ?? '').toString();
    final String status = (meeting['status'] ?? '').toString();
    final String fecha = _formatFecha(meeting['fechaHora']);
    final String hora = _formatHora(meeting['fechaHora']);
    final String idMeeting =
        (meeting['id_meeting'] ?? meeting['id'] ?? '').toString();

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
                  const Icon(Icons.event_note, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cita contrato $nroContract',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Contrato', nroContract),
              _detailRow('Fecha', fecha),
              _detailRow('Hora', hora),
              _detailRow('Técnico', tecnico.isEmpty ? 'Sin técnico' : tecnico),
              _detailRow(
                'Contratista',
                contratista.isEmpty ? 'Sin contratista' : contratista,
              ),
              _detailRow('Status', status),
              _detailRow('ID', idMeeting),
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
                      onPressed: () {
                        Navigator.pop(ctx); // cierra bottom sheet
                        _confirmCancel(nroContract, meeting);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
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

  void _confirmCancel(String nroContract, Map<String, dynamic> meeting) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar cancelación'),
            content: Text('¿Desea cancelar la cita del contrato $nroContract?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sí, cancelar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      final String idMeeting =
          (meeting['id_meeting'] ?? meeting['id'] ?? '').toString();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => CancelMeetingScreen(
                meetingId: idMeeting,
                clienteId: widget.idProspect,
                contract: nroContract,
              ),
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
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
              (value).isEmpty ? '-' : value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryColor,
      title: const Text(
        'Citas disponibles',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed:
              _appBarRefreshing
                  ? null
                  : () async {
                    setState(() => _appBarRefreshing = true);
                    try {
                      await _load(isRefreshing: true);
                    } finally {
                      if (mounted) setState(() => _appBarRefreshing = false);
                    }
                  },
          icon:
              _appBarRefreshing
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Icon(Icons.refresh, color: Colors.white),
        ),
        IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              // Aquí debes integrar tu servicio de logout
              // await otpService.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
      ],
      centerTitle: true,
      elevation: 4,
    );
  }

  Widget _buildBody() {
    if (_loading) {
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
              'Ocurrió un error al cargar las citas',
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
      return const Center(child: Text('No hay citas disponibles'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(isRefreshing: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _meetings.length,
        itemBuilder: (ctx, i) => _buildMeetingCard(_meetings[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
}
