// lib/screens/admin/prospects/prospect_create_screen.dart
import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';

class ProspectCreateScreen extends StatefulWidget {
  const ProspectCreateScreen({super.key});

  @override
  State<ProspectCreateScreen> createState() => _ProspectCreateScreenState();
}

class _ProspectCreateScreenState extends State<ProspectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProspectService _prospectService = ProspectService();
  final FranchiseService _franchiseService = FranchiseService();

  final TextEditingController _aradialIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _documentTypeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _planController = TextEditingController();

  List<dynamic> _franchises = [];
  String? _selectedFranchiseId;
  bool _isLoading = false;
  bool _franchisesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFranchises();
  }

  Future<void> _loadFranchises() async {
    try {
      final franchises = await _franchiseService.getAllFranchises();
      setState(() {
        _franchises = franchises;
        _franchisesLoaded = true;
      });
    } catch (e) {
      setState(() => _franchisesLoaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ciudades: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _prospectService.createProspect({
        'aradial_id': _aradialIdController.text,
        'name': _nameController.text,
        'last_name': _lastNameController.text,
        'document': _documentController.text,
        'document_type': _documentTypeController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'email': _emailController.text,
        'plan': _planController.text,
        'franchise_id': int.parse(
          _selectedFranchiseId!,
        ), // Convertir a int para cumplir con el API
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prospecto creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear prospecto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Crear Nuevo Prospecto',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Sección de Información Personal
              _buildSectionTitle('Información Personal'),

              TextFormField(
                controller: _aradialIdController,
                decoration: _buildInputDecoration('Aradial_id'),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El Aradial_id es requerido';
                  }
                  if (value.length > 16) {
                    return 'El nombre no debe exceder 255 caracteres';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('Nombre'),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.length > 255) {
                    return 'El nombre no debe exceder 255 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: _buildInputDecoration('Apellido'),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El apellido es requerido';
                  }
                  if (value.length > 255) {
                    return 'El apellido no debe exceder 255 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentController,
                decoration: _buildInputDecoration('Documento'),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El documento es requerido';
                  }
                  if (value.length > 255) {
                    return 'El documento no debe exceder 255 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentTypeController,
                decoration: _buildInputDecoration('Tipo de Documento'),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El tipo de documento es requerido';
                  }
                  if (value.length > 50) {
                    return 'El tipo de documento no debe exceder 50 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: _buildInputDecoration('Teléfono'),
                maxLength: 20,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  if (value.length > 20) {
                    return 'El teléfono no debe exceder 20 caracteres';
                  }
                  return null;
                },
              ),

              // Sección de Información de Contacto
              _buildSectionTitle('Información de Contacto'),

              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration('Dirección'),
                maxLength: 255,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección es requerida';
                  }
                  if (value.length > 255) {
                    return 'La dirección no debe exceder 255 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: _buildInputDecoration('Estado'),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La ciudad es requerida';
                  }
                  if (value.length > 100) {
                    return 'La ciudad no debe exceder 100 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _buildInputDecoration('Correo Electrónico'),
                keyboardType: TextInputType.emailAddress,
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El correo electrónico es requerido';
                  }
                  if (value.length > 255) {
                    return 'El correo electrónico no debe exceder 255 caracteres';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Correo electrónico inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _planController,
                decoration: _buildInputDecoration('Plan'),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El plan es requerido';
                  }
                  if (value.length > 100) {
                    return 'El plan no debe exceder 100 caracteres';
                  }
                  return null;
                },
              ),

              // Sección de Franquicia
              _buildSectionTitle('Ciudad'),

              if (_franchisesLoaded && _franchises.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedFranchiseId,
                  items:
                      _franchises.map((franchise) {
                        return DropdownMenuItem(
                          value: franchise['id'].toString(),
                          child: Text(
                            franchise['branch_office'] ??
                                franchise['name'] ??
                                'Ciudad sin nombre',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedFranchiseId = value);
                  },
                  decoration: _buildInputDecoration(
                    'Seleccione una ciudad',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La ciudad es requerida';
                    }
                    return null;
                  },
                ),
              if (!_franchisesLoaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_franchisesLoaded && _franchises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _buildEmptyState(
                    'Sin ciudad',
                    'No hay ciudades disponibles para asignar',
                    Icons.business,
                  ),
                ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Crear Prospecto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares para mejorar la UI
  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
