import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vnet_agenda/screens/User/crud/order/order_create_screen.dart';
import 'package:vnet_agenda/screens/User/crud/users/user_edit_screen.dart';
import 'package:vnet_agenda/screens/User/worker/home_worker_screen.dart';
import 'package:vnet_agenda/screens/init_select_user_screen.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
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

  final List<Map<String, String>> _motivos = [
    {'code': 'NAP', 'text': 'No hay puertos disponibles en la caja NAP'},
    {'code': 'POT', 'text': 'Potencia fuera de rango / Caja sin potencia'},
    {'code': 'ZON', 'text': 'No hay servicio en la zona'},
    {'code': 'FAC', 'text': 'No hay factibilidad en la residencia'},
  ];

  Future<void> _continuar() async {
    Navigator.push(
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
  }

  Future<void> _cancelar() async {
    if (_selectedMain != 1 || _selectedMotivo == null) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception', ''))),
      );
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Mi cuenta',
            onSelected: (value) async {
              const storage = FlutterSecureStorage();
              final userId = await storage.read(key: 'user_id');
              if (userId == null || userId.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo obtener el usuario'),
                    ),
                  );
                }
                return;
              }

              if (value == 'edit') {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserEditScreen(userId: userId),
                    ),
                  );
                }
              } else if (value == 'delete') {
                if (context.mounted) {
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
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const InitSelectUserScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
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
                if (context.mounted) {
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
      ),

      body: SingleChildScrollView(
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
                          .map((m) => _radioMotivoTile(m['code']!, m['text']!))
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
                      _selectedMain == 0 ? AppColors.primaryColor : Colors.red,
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
