import 'package:flutter/material.dart';
import 'package:vnet_agenda/screens/clientes/home_cliente_screen.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class SelectContractScreen extends StatefulWidget {
  final String clientDataId;
  final List<dynamic> contracts;
  final String document;

  const SelectContractScreen({
    super.key,
    required this.clientDataId,
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
                  children: [Text('Documento: ${widget.document}')],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Seleccione el contrato para la instalación:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // LISTA DE CONTRATOS
            Expanded(
              child:
                  widget.contracts.isEmpty
                      ? const Center(
                        child: Text('No hay contratos disponibles'),
                      )
                      : ListView.builder(
                        itemCount: widget.contracts.length,
                        itemBuilder: (context, index) {
                          final item = widget.contracts[index];

                          // Soportar ambos formatos: String (id) o Map (objeto contrato)
                          final String contractIdStr =
                              item is String
                                  ? item
                                  : (item?['contract_id']?.toString() ?? '');

                          final isSelected =
                              _selectedContractId == contractIdStr;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected ? Colors.blue[50] : null,
                            child: ListTile(
                              leading: Icon(
                                Icons.home_work,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                              title: Text(
                                'Contrato: ${contractIdStr.isNotEmpty ? contractIdStr : 'Sin ID'}',
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
                                  _selectedContractId = contractIdStr;
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
                onPressed: _selectedContractId != null ? _continueToHome : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continuar', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToHome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => HomeClienteScreen(
              clienteId: widget.clientDataId,
              contractId: _selectedContractId!,
            ),
      ),
    );
  }
}
