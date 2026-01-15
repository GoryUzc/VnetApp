import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_create_screen.dart';
import 'package:vnet_agenda/screens/User/worker/home_worker_screen.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/theme/app_text_styles.dart';

class PreInstallMeetingCheckScreen extends StatefulWidget {
  final String meetingId;
  final String prospectName;
  final String prospectId;
  final String userId;

  const PreInstallMeetingCheckScreen({
    Key? key,
    required this.meetingId,
    required this.prospectName,
    required this.prospectId,
    required this.userId,
  }) : super(key: key);

  @override
  State<PreInstallMeetingCheckScreen> createState() =>
      _PreInstallMeetingCheckScreenState();
}

class _PreInstallMeetingCheckScreenState
    extends State<PreInstallMeetingCheckScreen> {
  final MeetingService _meetingService = MeetingService();

  int? _selectedMain; // 0 = si y 1 = no
  String? _selectedMotivo; // Observación si no se instala
  bool _isLoading = false;

  final List<Map<String, String>> _motivos = [
    {'code': 'NAP', 'text': 'No hay puertos disponibles en la caja NAP'},
    {'code': 'POT', 'text': 'Potencia fuera de rango / Caja sin potencia'},
    {'code': 'ZON', 'text': 'No hay servicio en la zona'},
    {'code': 'FAC', 'text': 'No hay factibilidad en la residencia'},
  ];

  Future<void> _continuar() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(microseconds: 300));
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OrderCreateScreen(
              prospectName: widget.prospectName,
              prospectId: widget.prospectId,
              userId: widget.userId,
              meetingId: widget.meetingId,
            ),
      ),
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelar() async {
    if (_selectedMain != 1 || _selectedMotivo == null) return;

    setState(() {
      _isLoading = true;
    });

    const String status = 'cancelada';

    final obs =
        'No se puede realizar la instalación: ${_selectedMotivo ?? 'Motivo no especificado'}';
    try {
      await _meetingService.cancelMeeting(widget.meetingId, obs, status);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cita cancelada con exito')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeWorkerScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception', ''))),
        );
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
          'Verificacion previa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card(
                  title: '¿Se pueden realizar las condiciones de instalación?',
                  child: Column(
                    children: [
                      _radioTile(0, 'Se puede realizar la instalación'),
                      _radioTile(1, 'No se puede realizar la instalación'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedMain == 1) ...[
                  _card(
                    title: 'Selecciona el motivo',
                    child: Column(
                      children:
                          _motivos
                              .map(
                                (m) => _radioMotivoTile(m['code']!, m['text']!),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_selectedMain == 0 ||
                                (_selectedMain == 1 && _selectedMotivo != null))
                            ? (_selectedMain == 0 ? _continuar : _cancelar)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedMain == 0
                              ? AppColors.primaryColor
                              : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _selectedMain == 0
                          ? 'Continuar instalación'
                          : 'Cancelar cita',
                      style: AppTextStyles.buttonStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _radioTile(int value, String title) {
    return RadioListTile<int>(
      value: value,
      groupValue: _selectedMain,
      onChanged: (v) => setState(() => _selectedMain = v),
      title: Text(title, style: AppTextStyles.buttonStyle),
      activeColor: AppColors.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _radioMotivoTile(String code, String text) {
    return RadioListTile<String>(
      value: text,
      groupValue: _selectedMotivo,
      onChanged: (v) => setState(() => _selectedMotivo = v),
      title: Text(text, style: AppTextStyles.buttonStyle),
      activeColor: AppColors.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
