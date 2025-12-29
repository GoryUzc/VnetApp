import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vnet_agenda/services/crud/meeting_service.dart';
import 'package:intl/intl.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class MeetingDeatilTakeScreen extends StatefulWidget {
  final String? meetingId;
  final String? userId;
  const MeetingDeatilTakeScreen({super.key, this.meetingId, this.userId});

  @override
  State<MeetingDeatilTakeScreen> createState() =>
      _MeetingDetailTakeScreenState();
}

class _MeetingDetailTakeScreenState extends State<MeetingDeatilTakeScreen> {
  final _formKey = GlobalKey<FormState>();

  int? role;

  final Logger _logger = Logger();

  // Servicios
  final MeetingService _meetingService = MeetingService();
  final ProspectService _prospectService = ProspectService();
  final UserServices _userService = UserServices();

  // Diccionarios y listas
  Map<String, dynamic> meetingList = {};
  Map<String, dynamic> prospectList = {};

  // Variables para los datos del cliente
  String clienteNombre = '';
  String clienteDocumento = '';
  String clienteDirecion = '';
  String clientePLan = '';
  String clienteTelefono = '';
  String prospectId = '';
  DateTime dateTime = DateTime(2000, 1, 1, 8, 00);
  double latitude = 0.0;
  double longitude = 0.0;
  String citaId = '';
  // Estado
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage = '';
  bool _dateFormatInitialized = false;

  @override
  void initState() {
    super.initState();
    _initLoadData();
    initializeDateFormatting('es_ES', null).then((_) {
      if (mounted) {
        setState(() {
          _dateFormatInitialized = true;
        });
      }
    });
  }

  Future<void> _initLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasError = false;
    });
    try {
      final meetingData = await _meetingService.getMeetingDetails(
        widget.meetingId ?? '',
      );
      prospectId = meetingData['prospect_aradial_id'].toString();
      _logger.d('1:$prospectId');
      dateTime = DateTime.parse(meetingData['date_time1']);
      latitude = double.parse(meetingData['latitude']);
      longitude = double.parse(meetingData['longitude']);
      final prospectData = await _prospectService.getProspectDetails(
        prospectId,
      );
      final data = prospectData['prospect'];
      clienteNombre = _formatName(data);
      clienteDocumento = data['document']?.toString() ?? '';
      clienteDirecion = data['address']?.toString() ?? '';
      clientePLan = data['plan']?.toString() ?? '';
      clienteTelefono = data['phone']?.toString() ?? '';
      citaId = id(widget.meetingId);
      _logger.d('ID CITA: $citaId');

      final r = widget.userId ?? '';
      _logger.d('Usuario a consultar: $r');
      final idR = await _userService.getUserDetails(r);
      role = idR['role_id'];
      _logger.d('el Role del usuario es : $role');

      return;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String id(dynamic data) {
    final idM = data.toString();
    _logger.d('El ID de la Cita: $idM');
    return idM.isNotEmpty ? idM : AppStrings.anonymous;
  }

  String _formatName(dynamic clienteData) {
    final firstName = clienteData['name']?.toString() ?? '';
    final lastName = clienteData['last_name']?.toString() ?? '';
    final fullname = '$firstName $lastName'.trim();
    return fullname.isNotEmpty ? fullname : AppStrings.anonymous;
  }

  Future<void> _abrirEnMapaExterno(double latitude, double longitude) async {
    final String url;

    // Detectar si es iOS o Android/Web
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      url = 'https://maps.apple.com/?q=$latitude,$longitude';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se puede mostrar el mapa $url';
    }
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

  @override
  Widget build(BuildContext context) {
    if (!_dateFormatInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final formattedDate = DateFormat(
      'EEEE, d MMMM y',
      'es_ES',
    ).format(dateTime);
    final formattedTime = DateFormat('h:mm a', 'es_ES').format(dateTime);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          "Cita Agendada",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initLoadData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    Text(
                      'Cita agendada',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8.0),
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
                            // Informacion del cliente
                            _buildInfoRow(
                              icon: Icons.person,
                              title: 'Cliente',
                              value:
                                  clienteNombre.isNotEmpty
                                      ? clienteNombre
                                      : AppStrings.anonymous,
                            ),
                            const SizedBox(height: 12.0),

                            _buildInfoRow(
                              icon: Icons.badge,
                              title: 'Documento',
                              value:
                                  clienteDocumento.isNotEmpty
                                      ? clienteDocumento
                                      : AppStrings.anonymous,
                            ),
                            const SizedBox(height: 16.0),

                            _buildInfoRow(
                              icon: Icons.add_home,
                              title: 'Direccion',
                              value:
                                  clienteDirecion.isNotEmpty
                                      ? clienteDirecion
                                      : AppStrings.anonymous,
                            ),
                            const SizedBox(height: 16.0),

                            _buildInfoRow(
                              icon: Icons.wifi_2_bar_sharp,
                              title: 'Plan de internet',
                              value:
                                  clientePLan.isNotEmpty
                                      ? clientePLan
                                      : AppStrings.notAvailable,
                            ),
                            const SizedBox(height: 16.0),

                            const Divider(),
                            const SizedBox(height: 16.0),

                            // Detalles de la cita
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

                            const Divider(),
                            const SizedBox(height: 16.0),

                            // Ubicación
                            _buildInfoRow(
                              icon: Icons.location_on,
                              title: 'Ubicación',
                              value: 'Coordenadas seleccionadas',
                            ),
                            const SizedBox(height: 8.0),

                            Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Latitud: ${latitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Longitud: ${longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _abrirEnMapaExterno(
                                      latitude,
                                      longitude,
                                    ),
                                icon: const Icon(Icons.map, size: 20),
                                label: const Text('Ver en Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    Column(
                      children: [
                        if (role == 3)
                          ElevatedButton(
                            onPressed: () async {
                              await _takeMeeting(citaId);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Tomar cita',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (role == 4)
                          ElevatedButton(
                            onPressed: () async {
                              await _takeMeeting(citaId);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Tomar cita',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _takeMeeting(String id) async {
    try {
      await _meetingService.takeMeeting(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cita tomada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al tomar la cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
