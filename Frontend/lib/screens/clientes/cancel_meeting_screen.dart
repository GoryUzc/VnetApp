import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/clientes/cancel_success_screen.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/theme/app_text_styles.dart';

class CancelMeetingScreen extends StatefulWidget {
  final String meetingId;
  final String clienteId;
  final String contract;

  const CancelMeetingScreen({
    Key? key,
    required this.meetingId,
    required this.clienteId,
    required this.contract,
  }) : super(key: key);

  @override
  State<CancelMeetingScreen> createState() => _CancelMeetingScreenState();
}

class _CancelMeetingScreenState extends State<CancelMeetingScreen> {
  final Logger _logger = Logger();
  final MeetingService _meetingService = MeetingService();
  final _observationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _dataMeeting = {};

  int? _selectedReason; // 0 cliente, 1 técnico, 2 otro
  bool _loadingDetails = true;
  bool _submitting = false;
  String? _reasonError; // feedback si no selecciona motivo

  String get _status {
    if (_selectedReason == 1) return 'Perdida';
    return 'cancelada';
  }

  @override
  void initState() {
    super.initState();
    _loadMeetingDetails();
  }

  Future<void> _loadMeetingDetails() async {
    try {
      final data = await _meetingService.getMeetingDetailProspect(
        widget.meetingId,
        widget.clienteId,
      );
      if (mounted) {
        setState(() {
          _dataMeeting = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error cargando la cita: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDetails = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      setState(() => _reasonError = 'Selecciona un motivo de cancelación');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _reasonError = null;
    });

    try {
      final motivo = _mapReason(_selectedReason);
      final observation = _observationController.text.trim();
      final status = _status;

      // Usamos la firma de 2 parámetros para compatibilidad
      await _meetingService.cancelMeeting(
        widget.meetingId,
        observation,
        status,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => CancelSuccessScreen(
                prospectId: widget.clienteId,
                contract: widget.contract,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Manejo de loading inicial y parseo seguro de fecha
    if (_loadingDetails) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: const Text(
            "Citas Disponibles",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String? dateStr = _dataMeeting['date_time1'] as String?;
    DateTime? fechaHora;
    if (dateStr != null) {
      try {
        fechaHora = DateTime.parse(dateStr);
      } catch (_) {
        fechaHora = null;
      }
    }
    final formattedDate =
        fechaHora != null ? _formatDate(fechaHora) : 'No disponible';
    final formattedTime =
        fechaHora != null ? _formatTime(fechaHora) : 'No disponible';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          "Cancelar Cita",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícono de advertencia
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning, color: Colors.orange, size: 60),
            ),
            const SizedBox(height: 24.0),

            // Título
            const Text(
              '¿Estás seguro de cancelar tu cita?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),

            Text(
              'Selecciona el motivo y proporciona una breve observación',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32.0),

            // Tarjeta con detalles de la cita
            Card(
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      title: 'Fecha',
                      value: formattedDate,
                    ),
                    const SizedBox(height: 12.0),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      title: 'Hora',
                      value: formattedTime,
                    ),
                    const SizedBox(height: 16.0),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      title: 'Dirección',
                      value: _dataMeeting['address'] ?? 'No disponible',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32.0),

            // Formulario de cancelación
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motivo de cancelación',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _radioTile(0, 'Por motivo del cliente'),
                  _radioTile(1, 'El técnico no se presentó'),
                  _radioTile(2, 'Otro motivo'),
                  if (_reasonError != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Text(
                        'Selecciona un motivo de cancelación',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Observaciones adicionales',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _observationController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe brevemente el motivo...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator:
                        (val) =>
                            val == null || val.trim().isEmpty
                                ? 'Por favor ingresa una observación'
                                : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _submitting
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                'Cancelar cita',
                                style: AppTextStyles.buttonStyle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _radioTile(int value, String title) {
    return RadioListTile<int>(
      value: value,
      groupValue: _selectedReason,
      onChanged: (v) => setState(() => _selectedReason = v),
      title: Text(title, style: AppTextStyles.subtitle),
      activeColor: AppColors.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _mapReason(int? r) {
    switch (r) {
      case 0:
        return 'Cliente';
      case 1:
        return 'Técnico';
      case 2:
        return 'Otro';
      default:
        return 'Desconocido';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
