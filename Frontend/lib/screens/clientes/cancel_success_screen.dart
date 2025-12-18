import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/clientes/create_meeting_cliente_creen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/theme/app_text_styles.dart';

class CancelSuccessScreen extends StatefulWidget {
  final String prospectId;
  final String contract;
  const CancelSuccessScreen({
    Key? key,
    required this.prospectId,
    required this.contract,
  }) : super(key: key);
  @override
  State<CancelSuccessScreen> createState() => _CancelSuccessScreenState();
}

class _CancelSuccessScreenState extends State<CancelSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const Text(
                'Cita cancelada con éxito',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Tu solicitud ha sido registrada.\nEn breve recibirás confirmación.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40.0),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CreateMeetingClienteSCreen(
                              prospectAradialId: widget.prospectId,
                              contractId: widget.contract,
                            ),
                      ),
                      (route) => false,
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Crear cita',
                  style: AppTextStyles.buttonStyle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
