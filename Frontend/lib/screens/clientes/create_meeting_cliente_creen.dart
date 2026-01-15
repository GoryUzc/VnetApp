import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/web.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:vnet_agenda/screens/clientes/created_successfully_meeting_screen.dart';
import 'package:vnet_agenda/services/others/cliente_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/theme/app_text_styles.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:intl/intl.dart';

class CreateMeetingClienteSCreen extends StatefulWidget {
  final String prospectAradialId;
  final String contractId;

  const CreateMeetingClienteSCreen({
    Key? key,
    required this.prospectAradialId,
    required this.contractId,
  }) : super(key: key);

  @override
  CrearCitaScreenState createState() => CrearCitaScreenState();
}

class CrearCitaScreenState extends State<CreateMeetingClienteSCreen> {
  final Logger _logger = Logger();
  final ClienteService _clienteService = ClienteService();
  DateTime? _fechaHora1;
  String? _horaSeleccionada;
  LatLng? _selectedLocation;
  String? _adrressReference;
  final FranchiseService _franchiseService = FranchiseService();
  bool _isLoading = false;
  String _errorMessage = '';
  final MapController _mapController = MapController();
  final TextEditingController _busquedaController = TextEditingController();

  final TextEditingController _ubicacionReferenciaController =
      TextEditingController();
  // Catalogo
  List<Map<String, dynamic>> _franchises = [];
  bool _loadingFranchises = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fechaHora1Controller = TextEditingController();

  // Seleccionados
  String? _selectedFranchiseId; // Corregí el nombre de la variable

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
    _loadFranchises();

    // Establecer una fecha inicial valida (proximo dia laboral)
    DateTime now = DateTime.now();
    DateTime initialDate = _obtenerProximoDiaLaboral(now);

    // Establecer hora dentro del horario laboral (8:00 a.m.)
    initialDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      8, // hora: 8:00 am
      0, // Minutos
    );
    _fechaHora1 = initialDate;
    _fechaHora1Controller.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(initialDate);
  }

  Future<void> _loadFranchises() async {
    setState(() => _loadingFranchises = true);
    try {
      final data = await _franchiseService.getAllFranchises();
      setState(() {
        _franchises = data;
        _franchises = data.map((e) => e).toList();
        _franchises.sort((a, b) {
          String nombreA = a['branch_office']?.toString().toLowerCase() ?? '';
          String nombreB = b['branch_office']?.toString().toLowerCase() ?? '';

          return nombreA.compareTo(nombreB);
        });
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar las franquicias'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingFranchises = false);
    }
  }

  // Funcion para obtener el proximo dia laboral
  DateTime _obtenerProximoDiaLaboral(DateTime fecha) {
    DateTime fechaActual = fecha;

    // Avanzar hasta encontrar un dia laboral
    while (!_esDiaLaboral(fechaActual)) {
      fechaActual = fechaActual.add(const Duration(days: 1));
    }
    return fechaActual;
  }

  bool _esDiaLaboral(DateTime date) {
    return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
  }

  @override
  void dispose() {
    _fechaHora1Controller.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Por favor, habilita los servicios de ubicación';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permisos de ubicación denegados';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Los permisos de ubicación están permanentemente denegados';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation!, 15.0);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener la ubicación: $e';
      });
    }
  }

  bool _esHorarioLaboral(TimeOfDay time) {
    return time.hour >= 8 && time.hour < 16;
  }

  // void _validarFechaHora1(String value) {
  //   if (value.isEmpty) {
  //     setState(() {
  //       _fechaHora1 = null;
  //     });
  //     return;
  //   }

  //   try {
  //     final fecha = DateTime.parse(value);

  //     if (!_esDiaLaboral(fecha)) {
  //       setState(() {
  //         _errorMessage = 'Solo se permiten citas de lunes a viernes';
  //         _fechaHora1 = null;
  //       });
  //       return;
  //     }

  //     final time = TimeOfDay.fromDateTime(fecha);
  //     if (!_esHorarioLaboral(time)) {
  //       setState(() {
  //         _errorMessage = 'El horario laboral es de 8:00 AM a 4:00 PM';
  //         _fechaHora1 = null;
  //       });
  //       return;
  //     }

  //     setState(() {
  //       _fechaHora1 = fecha;
  //       _errorMessage = '';
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _fechaHora1 = null;
  //       _errorMessage = 'Fecha u hora inválida';
  //     });
  //   }
  // }

  List<String> _horasLaborales() {
    final horas = <String>[];
    for (int h = 8; h <= 16; h++) {
      for (int m = 0; m < 60; m += 30) {
        if (h == 16 && m > 0) break; // solo 16:00
        horas.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
      }
    }
    return horas;
  }

  Future<void> _confirmarCita() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ⭐ NUEVO: unimos fecha y hora
    if (_fechaHora1Controller.text.isEmpty || _horaSeleccionada == null) {
      setState(() => _errorMessage = 'Selecciona fecha y hora');
      return;
    }
    final fecha = DateTime.parse(_fechaHora1Controller.text); // yyyy-MM-dd
    final hora = TimeOfDay.fromDateTime(
      DateFormat('HH:mm').parse(_horaSeleccionada!),
    );
    _fechaHora1 = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    if (!_esDiaLaboral(_fechaHora1!)) {
      setState(
        () => _errorMessage = 'Solo se permiten citas de lunes a viernes',
      );
      return;
    }

    final time = TimeOfDay.fromDateTime(_fechaHora1!);
    if (!_esHorarioLaboral(time) || time.minute % 30 != 0) {
      setState(
        () => _errorMessage = 'Elige un horario entre 8:00 AM y 4:00 PM',
      );
      return;
    }

    if (_selectedLocation == null || _selectedFranchiseId == null) {
      setState(() => _errorMessage = 'Por favor, completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _adrressReference = _ubicacionReferenciaController.text.trim();

    try {
      final Map<String, dynamic> citaData = {
        'prospect_aradial_id': widget.prospectAradialId,
        'date_time1': DateFormat('yyyy-MM-dd HH:mm:ss').format(_fechaHora1!),
        'franchise_id': _selectedFranchiseId,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'nro_contract': widget.contractId,
        'direcc_refe': _adrressReference,
      };

      final response = await _clienteService.createMeetingProspect(citaData);
      _logger.d('Respuesta: $response');
      if (!mounted) return;
      if (response['meeting'] != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => CreatedSuccessfullyScreen(
                  citaData: citaData,
                  clienteId: widget.prospectAradialId,
                ),
          ),
        );
      } else {
        setState(
          () =>
              _errorMessage = response['message'] ?? 'Error al agendar la cita',
        );
      }
    } catch (e) {
      String errorMsg = e.toString();
      setState(
        () =>
            _errorMessage =
                errorMsg.contains('422:')
                    ? errorMsg.replaceFirst('422: ', '')
                    : 'Error: $errorMsg',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Future<void> _abrirEnMapaExterno() async {
  //   if (_selectedLocation == null) return;

  //   final String url;
  //   if (Theme.of(context).platform == TargetPlatform.iOS) {
  //     url =
  //         'https://maps.apple.com/?q=${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
  //   } else {
  //     url =
  //         'https://www.google.com/maps/search/?api=1&query=${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
  //   }

  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     setState(() {
  //       _errorMessage = 'No se pudo abrir la aplicación de mapas';
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          "Agendar Nueva Cita",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Selector de Fecha y Hora Inicial
                  Column(
                    children: [
                      // ① Selector de FECHA (sin hora)
                      DateTimePicker(
                        controller: _fechaHora1Controller,
                        type: DateTimePickerType.date,
                        dateMask: 'yyyy-MM-dd',
                        firstDate: _obtenerProximoDiaLaboral(DateTime.now()),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        icon: const Icon(Icons.calendar_today),
                        dateLabelText: 'Fecha',
                        selectableDayPredicate: (date) => _esDiaLaboral(date),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Selecciona fecha'
                                    : null,
                        onChanged: (val) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // ② Dropdown de HORAS (8:00-16:00, bloques 30 min)
                      DropdownButtonFormField<String>(
                        value: _horaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        items:
                            _horasLaborales().map((hora) {
                              return DropdownMenuItem(
                                value: hora,
                                child: Text(hora),
                              );
                            }).toList(),
                        validator:
                            (value) => value == null ? 'Selecciona hora' : null,
                        onChanged:
                            (hora) => setState(() => _horaSeleccionada = hora),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Selector de Franquicia
                  _franchiseDropdown(),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Toque el mapa para cambiar la ubicación',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _obtenerUbicacionActual,
                          icon: const Icon(Icons.my_location),
                          label: const Text(
                            'Mi Ubicación',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),
                  // Mapa para seleccionar ubicación
                  _buildMapSection(),
                  const SizedBox(height: 16.0),

                  // Información de ubicación seleccionada
                  _buildLocationInfo(),

                  const SizedBox(height: 24.0),

                  // Botón para confirmar cita
                  ElevatedButton(
                    onPressed: _confirmarCita,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Confirmar Cita',
                      style: AppTextStyles.buttonStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3), // fondo semi-transparente
              child: const Center(
                child: CircularProgressIndicator(), // ← el círculo girando
              ),
            ),
        ],
      ),
    );
  }

  Widget _franchiseDropdown() {
    if (_loadingFranchises) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedFranchiseId, // ✅ CORREGIDO: nombre de variable
      items:
          _franchises.map((f) {
            return DropdownMenuItem<String>(
              value: f['id'].toString(),
              child: Text(
                (f['branch_office'] ?? f['name'] ?? 'Franquicia').toString(),
              ),
            );
          }).toList(),
      onChanged: (v) => setState(() => _selectedFranchiseId = v),
      decoration: const InputDecoration(
        labelText: 'Ciudad',
        border: OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
    );
  }

  Widget _buildMapSection() {
    return SizedBox(
      height: 300,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _selectedLocation ?? const LatLng(10.506098, -66.9146017),
          zoom: 13.0,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers:
                _selectedLocation != null
                    ? [
                      Marker(
                        point: _selectedLocation!,
                        builder:
                            (ctx) => const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                      ),
                    ]
                    : [],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingrese Ubicacion referencial',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _ubicacionReferenciaController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Ejemplo: Cerca del parque central, frente a la iglesia',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
