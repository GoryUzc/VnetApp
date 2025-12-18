import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:vnet_agenda/screens/clientes/cancel_meeting_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/theme/app_text_styles.dart';

class AvailableMeetingsScreen extends StatefulWidget {
  final String prospectId;
  const AvailableMeetingsScreen({Key? key, required this.prospectId})
    : super(key: key);

  @override
  State<AvailableMeetingsScreen> createState() =>
      _AvailableMeetingsScreenState();
}

class _AvailableMeetingsScreenState extends State<AvailableMeetingsScreen> {
  final MeetingService _meetingService = MeetingService();

  Map<String, List<String>> _meetings = {}; // {contrato:[ids]}
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      final data = await _meetingService.getMeetingContractProspect(
        widget.prospectId,
      );
      setState(() {
        _meetings = Map<String, List<String>>.from(
          data['meetings'].map(
            (k, v) =>
                MapEntry(k, (v as List).map((id) => id.toString()).toList()),
          ),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMeetings,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Citas disponibles',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
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
      ),
      body:
          _meetings.isEmpty
              ? const Center(child: Text('No hay citas para mostrar'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _meetings.length,
                itemBuilder: (_, index) {
                  final contract = _meetings.keys.elementAt(index);
                  final ids = _meetings[contract]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          'Contrato $contract',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...ids.map(
                        (id) => _meetingsTitle(
                          meetingId: id,
                          onCancel: () => _onCancel(context, id),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _meetingsTitle({
    required String meetingId,
    required VoidCallback onCancel,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          'Cita ID: $meetingId',
          style: AppTextStyles.buttonStyle.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: onCancel,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _onCancel(BuildContext context, String meetingId) async {
    final contract = _meetings.keys.firstWhere(
      (k) => _meetings[k]!.contains(meetingId),
    );
    final bool? confirm = await showCancelConfirmDialog(context);
    if (confirm == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => CancelMeetingScreen(
                meetingId: meetingId,
                contract: contract,
                clienteId: widget.prospectId,
              ),
        ),
      );
    }
  }

  Future<bool?> showCancelConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Estás seguro de cancelar esta cita?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sí, cancelar'),
              ),
            ],
          ),
    );
  }
}
