import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vnet_agenda/screens/clientes/available_meetings_screen.dart';
import 'package:vnet_agenda/screens/clientes/select_contract_Screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/services/authentication/otp_service.dart';

Logger _logger = Logger();

class VerifyOtpScreen extends StatefulWidget {
  final String document;
  final String email;
  final List<dynamic> contractIds;
  final dynamic clienteId;
  // final String selectedContractorId;
  const VerifyOtpScreen({
    super.key,
    required this.document,
    required this.email,
    required this.contractIds,
    required this.clienteId,
    // required this.selectedContractorId,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final OtpService _otpService = OtpService();
  final TextEditingController _otpController = TextEditingController();
  String _meetingId = '';
  String idProspect = '';

  bool _isLoading = false;
  bool _hasMeetingExist = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await _otpService.verifyOtp(
        _otpController.text.trim(),
        widget.email,
        widget.document,
      );
      idProspect = result['prospectId'];
      _logger.d('El cliente es: $result');
      _logger.d('El cliente Id 1: $idProspect');
      _meetingId = result['meeting']?.toString() ?? '';
      _hasMeetingExist = result['hasMeeting'] ?? false;
      _logger.d('_hasMeetingExist: $_hasMeetingExist');
      if (_hasMeetingExist) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => AvailableMeetingsScreen(idProspect: idProspect),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => SelectContractScreen(
                  clientDataId: idProspect,
                  contracts: widget.contractIds,
                  document: widget.document,
                ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          "Verificación OTP",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  "assets/images/image001.png",
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Ingrese el código enviado a su correo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el código';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Verificar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
