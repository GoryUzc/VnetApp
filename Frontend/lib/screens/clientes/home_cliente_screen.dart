import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/clientes/create_meeting_cliente_creen.dart';
import 'package:vnet_agenda/services/others/cliente_service.dart';
import 'package:vnet_agenda/strings/app_strings.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/theme/app_text_styles.dart';

// Logger _logger = Logger();

class HomeClienteScreen extends StatefulWidget {
  final String clienteId;
  final String contractId;

  const HomeClienteScreen({
    Key? key,
    required this.clienteId,
    required this.contractId,
  }) : super(key: key);

  @override
  _HomeClienteScreenState createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  final ClienteService _clienteService = ClienteService();
  Map<String, dynamic> _clienteData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData({bool isRefreshing = false}) async {
    if (!isRefreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      _logger.d('ID A CONSULTAR ${widget.clienteId}');
      final response = await _clienteService.getClient(widget.clienteId);
      if (response.containsKey('prospect') && response['prospect'] != null) {
        setState(() {
          _clienteData = response['prospect'];
          _isLoading = false;
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

  String _formatName(Map<String, dynamic> userData) {
    final firstName = userData['name'] ?? '';
    final lastName = userData['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : AppStrings.anonymous;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFCC04FF),
        title: const Text(
          "Perfil de Usuario",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: () => _loadUserData(isRefreshing: true),
          ),
        ],
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
                      onPressed: _loadUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUserHeader(),
                    const SizedBox(height: 24.0),
                    _buildUserTable(),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CreateMeetingClienteSCreen(
                                  prospectAradialId: widget.clienteId,
                                  contractId: widget.contractId,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Crear Cita',
                        style: AppTextStyles.buttonStyle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserHeader() {
    final fullName = _formatName(_clienteData);
    final plan = _clienteData['plan'] ?? AppStrings.notAvailable;

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primaryColor,
          child: Text(
            fullName.isNotEmpty
                ? '${fullName[0]}${fullName.contains(' ') ? fullName.split(' ')[1][0] : ''}'
                : 'US',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4.0),
        Text(
          plan,
          style: AppTextStyles.subtitle.copyWith(color: AppColors.primaryColor),
        ),
      ],
    );
  }

  Widget _buildUserTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(2)},
        children: [
          _buildTableRow(AppStrings.name, _formatName(_clienteData)),
          _buildTableRow(
            AppStrings.documentType,
            _clienteData['document_type'],
          ),
          // _buildTableRow('numero contrato', widget.contractId),
          _buildTableRow(AppStrings.document, _clienteData['document']),
          _buildTableRow(AppStrings.phone, _clienteData['phone']),
          _buildTableRow(AppStrings.email, _clienteData['email']),
          _buildTableRow(AppStrings.address, _clienteData['address']),
          _buildTableRow(AppStrings.city, _clienteData['city']),
          _buildTableRow(AppStrings.plan, _clienteData['plan']),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String? value) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            value?.isNotEmpty == true ? value! : AppStrings.notAvailable,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
