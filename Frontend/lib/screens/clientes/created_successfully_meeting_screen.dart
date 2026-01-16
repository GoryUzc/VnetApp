import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/clientes/available_meetings_screen.dart';
import 'package:vnet_agenda/services/others/cliente_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatedSuccessfullyScreen extends StatefulWidget {
  final Map<String, dynamic> citaData;
  final String clienteId;

  const CreatedSuccessfullyScreen({
    Key? key,
    required this.citaData,
    required this.clienteId,
  }) : super(key: key);

  @override
  State<CreatedSuccessfullyScreen> createState() =>
      _CreatedSuccessfullyScreenState();
}

class _CreatedSuccessfullyScreenState extends State<CreatedSuccessfullyScreen> {
  final ClienteService _clienteService = ClienteService();
  final Logger _logger = Logger();
  Map<String, dynamic> _clienteData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _dateFormatInitialized = false;

  // Variables para almacenar datos del cliente
  String clienteNombre = '';
  String clienteDocumento = '';
  String clienteDireccion = '';
  String clientePlan = '';

  @override
  void initState() {
    super.initState();
    // Inicializar el formato de fechas
    initializeDateFormatting('es_ES', null).then((_) {
      if (mounted) {
        setState(() {
          _dateFormatInitialized = true;
        });
      }
    });
    _loadClientData();
  }

  Future<void> _loadClientData({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final response = await _clienteService.getClient(widget.clienteId);
      if (response.containsKey('prospect') && response['prospect'] != null) {
        setState(() {
          _clienteData = response['prospect'];
          _isLoading = false;
          _hasError = false;
          // Extraer datos del cliente
          clienteNombre = _formatName(_clienteData);
          clienteDocumento = _clienteData['document'];
          clienteDireccion =
              _clienteData['address']?.toString() ?? 'No disponible';
          clientePlan = _clienteData['plan']?.toString() ?? 'No especificado';
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No se encontraron datos del usuario';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _abrirEnMapaExterno(double lat, double lng) async {
    final platform = Theme.of(context).platform;

    Uri url;
    if (platform == TargetPlatform.iOS) {
      url = Uri.parse('apple.maps://?q=$lat,$lng');
    } else {
      url = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    }

    try {
      final bool canLaunch = await canLaunchUrl(url);

      if (!mounted) return;

      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Si necesitas mostrar un Snackbar o usar el context aquí,
        // el check de 'mounted' de arriba ya te protege.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de mapas'),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error al abrir mapa: $e');
    }
  }

  String _formatName(Map<String, dynamic> clienteData) {
    final firstName = clienteData['name']?.toString() ?? '';
    final lastName = clienteData['last_name']?.toString() ?? '';
    final fullname = '$firstName $lastName'.trim();
    return fullname.isNotEmpty ? fullname : AppStrings.anonymous;
  }

  @override
  Widget build(BuildContext context) {
    if (!_dateFormatInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fechaHora = DateTime.parse(widget.citaData['date_time1']);
    final formattedDate = DateFormat(
      'EEEE, d MMMM y',
      'es_ES',
    ).format(fechaHora);
    final formattedTime = DateFormat('h:mm a', 'es_ES').format(fechaHora);

    final latitude = widget.citaData['latitude'] ?? 0.0;
    final longitude = widget.citaData['longitude'] ?? 0.0;

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
                      _errorMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadClientData,
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
                    // Icono de éxito
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

                    // Título de confirmación
                    const Text(
                      '¡Cita Agendada Exitosamente!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),

                    Text(
                      'Los detalles de tu cita han sido registrados',
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
                            // Información del cliente
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
                                      : AppStrings.notAvailable,
                            ),
                            const SizedBox(height: 16.0),

                            _buildInfoRow(
                              icon: Icons.add_home,
                              title: 'Direccion',
                              value:
                                  clienteDireccion.isNotEmpty
                                      ? clienteDireccion
                                      : AppStrings.notAvailable,
                            ),
                            const SizedBox(height: 16.0),

                            _buildInfoRow(
                              icon: Icons.wifi_2_bar_sharp,
                              title: 'Plan de internet',
                              value:
                                  clientePlan.isNotEmpty
                                      ? clientePlan
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
                              value: widget.citaData['direcc_refe'] ?? '',
                            ),
                            const SizedBox(height: 16.0),

                            // Botón para abrir en maps
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _abrirEnMapaExterno(
                                      latitude,
                                      longitude,
                                    ),
                                icon: const Icon(Icons.map, size: 20),
                                label: const Text(
                                  'Ver en Maps',
                                  style: TextStyle(color: Colors.white),
                                ),
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

                    // Botones de acción
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Volver al inicio o a la pantalla anterior
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AvailableMeetingsScreen(
                                      idProspect: widget.clienteId,
                                    ),
                              ),
                            );
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
                            'Volver al Inicio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
}
