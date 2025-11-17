import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/clientes/verify_otp_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class SelectContractScreen extends StatefulWidget {
  final Map<String, dynamic> clientData;
  final List<Map<String, dynamic>> contracts;
  final String document;

  const SelectContractScreen({
    super.key,
    required this.clientData,
    required this.contracts,
    required this.document,
  });

  @override
  State<SelectContractScreen> createState() => _SelectContractScreenState();
}

class _SelectContractScreenState extends State<SelectContractScreen> {
  String? _selectedContractId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Contrato'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO DEL CLIENTE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.clientData['full_name'] ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Documento: ${widget.document}'),
                    Text('Email: ${widget.clientData['email']}'),
                    Text('Contratos disponibles: ${widget.contracts.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TÍTULO DE SELECCIÓN
            const Text(
              'Seleccione el contrato para la instalación:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // LISTA DE CONTRATOS
            Expanded(
              child:
                  widget.contracts.isEmpty
                      ? const Center(child: Text('No hay contratos disponibles'))
                      : ListView.builder(
                        itemCount: widget.contracts.length,
                        itemBuilder: (context, index) {
                          final contract = widget.contracts[index];
                          final isSelected =
                              _selectedContractId == contract['contract_id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected ? Colors.blue[50] : null,
                            child: ListTile(
                              leading: Icon(
                                Icons.home_work,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                              title: Text(
                                'Contrato: ${contract['contract_id']}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dirección: ${contract['address']}'),
                                  Text(
                                    'Sucursal: ${contract['branch_office']}',
                                  ),
                                  if (contract['services'] != null &&
                                      contract['services'].isNotEmpty)
                                    Text(
                                      'Servicio: ${contract['services'][0]['package_name']}',
                                    ),
                                ],
                              ),
                              trailing:
                                  isSelected
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : null,
                              onTap: () {
                                setState(() {
                                  _selectedContractId = contract['contract_id'];
                                });
                              },
                            ),
                          );
                        },
                      ),
            ),

            const SizedBox(height: 20),

            // BOTÓN CONTINUAR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedContractId != null ? _continueToOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuar con OTP',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToOtp() {
    // Navegar a verificación OTP con el contrato seleccionado
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VerifyOtpScreen(
              email: widget.clientData['email'],
              // selectedContractorId: _selectedContractId ?? '',
              document: widget.document,
            ),
      ),
    );
  }
}
