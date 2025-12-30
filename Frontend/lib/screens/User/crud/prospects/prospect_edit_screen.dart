import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/crud/prospect_service.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/theme/app_colors.dart';
import 'package:vnet_agenda/strings/app_strings.dart';

class ProspectEditScreen extends StatefulWidget {
  final String prospectId;

  const ProspectEditScreen({super.key, required this.prospectId});

  @override
  State<ProspectEditScreen> createState() => _ProspectEditScreenState();
}

class _ProspectEditScreenState extends State<ProspectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProspectService _prospectService = ProspectService();
  final FranchiseService _franchiseService = FranchiseService();
  final AuthService _authService = AuthService();

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

  List<Map<String, dynamic>> _franchises = [];
  String? _selectedFranchiseId; //id de franchise del usuario
  int? _userRoleId; //role del usuario
  String? _userFrachiseId; //Id de la franchises del user
  bool _isLoading = false;
  bool _franchisesLoaded = false;
  bool _prospectLoaded = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final futures = await Future.wait([
        _franchiseService.getAllFranchises(),
        _prospectService.getProspectDetails(widget.prospectId),
      ]);

      // Procesar franquicias
      final franchises = futures[0];
      if (franchises is List) {
        setState(() {
          _franchises =
              franchises
                  .map((franchise) => franchise as Map<String, dynamic>)
                  .toList();
          _franchisesLoaded = true;
        });
      } else {
        throw Exception('Formato de respuesta inesperado para franquicias');
      }

      // Procesar datos del prospecto
      final prospectData = _processProspectResponse(futures[1]);

      setState(() {
        _aradialIdController.text = prospectData['aradial_id'] ?? '';
        _nameController.text = prospectData['name'] ?? '';
        _lastNameController.text = prospectData['last_name'] ?? '';
        _documentController.text = prospectData['document'] ?? '';
        _documentTypeController.text = prospectData['document_type'] ?? '';
        _phoneController.text = prospectData['phone'] ?? '';
        _addressController.text = prospectData['address'] ?? '';
        _cityController.text = prospectData['city'] ?? '';
        _emailController.text = prospectData['email'] ?? '';
        _planController.text = prospectData['plan'] ?? '';

        if (prospectData['franchise_id'] != null) {
          _selectedFranchiseId = prospectData['franchise_id'].toString();
        }

        _prospectLoaded = true;
        _isLoading = false;
      });
      final userData = await _authService.getDataUserRoleFranchise();
      _userRoleId = int.tryParse(userData['role']);
      _userFrachiseId = userData['franchise'];
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar(e, stackTrace);
    }
  }

  Map<String, dynamic> _processProspectResponse(dynamic response) {
    if (response is Map<String, dynamic> && response.containsKey('prospect')) {
      // Si la respuesta tiene la estructura { "message": "...", "prospect": { ... } }
      return response['prospect'] as Map<String, dynamic>;
    } else if (response is Map<String, dynamic>) {
      // Si la respuesta es directamente el objeto prospecto
      return response;
    } else {
      throw Exception('Formato de respuesta inesperado del servidor');
    }
  }

  void _showErrorSnackBar(dynamic error, [StackTrace? stackTrace]) {
    String message;

    if (error.toString().contains('Network')) {
      message = AppStrings.networkError;
    } else if (error.toString().contains('401')) {
      message = AppStrings.unauthorizedError;
    } else if (error.toString().contains('404')) {
      message = AppStrings.notFoundError;
    } else {
      message = AppStrings.genericError;
      ('Error al cargar datos:', error: error, stackTrace: stackTrace);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _updateProspect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _prospectService.updateProspect(widget.prospectId, {
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
        'franchise_id': int.parse(_selectedFranchiseId!), // Convertir a int
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.prospectUpdated),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      String message;
      if (e.toString().contains('422')) {
        message = AppStrings.validationError;
      } else {
        message = AppStrings.errorUpdatingProspect;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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
          'Editar Prospecto',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 4,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (!_prospectLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildForm();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            AppStrings.errorLoadingData,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              AppStrings.retry,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Sección de Información Personal
              _buildSectionTitle(AppStrings.personalInformation),

              TextFormField(
                controller: _aradialIdController,
                decoration: _buildInputDecoration('Aradial_id'),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 255) {
                    return AppStrings.maxCharactersError(255);
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(AppStrings.name),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 255) {
                    return AppStrings.maxCharactersError(255);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: _buildInputDecoration(AppStrings.lastName),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 255) {
                    return AppStrings.maxCharactersError(255);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentController,
                decoration: _buildInputDecoration(AppStrings.document),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 255) {
                    return AppStrings.maxCharactersError(255);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentTypeController,
                decoration: _buildInputDecoration(AppStrings.documentType),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 50) {
                    return AppStrings.maxCharactersError(50);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: _buildInputDecoration(AppStrings.phone),
                maxLength: 20,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 20) {
                    return AppStrings.maxCharactersError(20);
                  }
                  return null;
                },
              ),

              // Sección de Información de Contacto
              _buildSectionTitle(AppStrings.contactInformation),

              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration(AppStrings.address),
                maxLength: 255,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 255) {
                    return AppStrings.maxCharactersError(255);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: _buildInputDecoration(AppStrings.city),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 100) {
                    return AppStrings.maxCharactersError(100);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _buildInputDecoration(AppStrings.email),
                keyboardType: TextInputType.emailAddress,
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 255) {
                    return AppStrings.maxCharactersError(255);
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return AppStrings.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _planController,
                decoration: _buildInputDecoration(AppStrings.plan),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (value.length > 100) {
                    return AppStrings.maxCharactersError(100);
                  }
                  return null;
                },
              ),

              // Sección de Franquicia
              _buildSectionTitle(AppStrings.franchise),
              if (_franchisesLoaded && _franchises.isNotEmpty)
                (_userRoleId == 1)
                    ? DropdownButtonFormField<String>(
                      value: _selectedFranchiseId,
                      items:
                          _franchises.map((franchise) {
                            return DropdownMenuItem(
                              value: franchise['id'].toString(),
                              child: Text(
                                franchise['branch_office'] ??
                                    franchise['name'] ??
                                    AppStrings.untitledFranchise,
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedFranchiseId = value);
                      },
                      decoration: _buildInputDecoration(
                        AppStrings.selectFranchise,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.fieldRequired;
                        }
                        return null;
                      },
                    )
                    : TextFormField(
                      controller: TextEditingController(
                        text:
                            _franchises.firstWhere(
                              (f) => f['id'].toString() == _userFrachiseId,
                              orElse:
                                  () => <String, dynamic>{
                                    'name': 'Franchise no encontrada',
                                  },
                            )['name'],
                      ),
                      decoration: _buildInputDecoration(AppStrings.franchise),
                      readOnly: true, //Deshabilitado para roles 2,3, 4
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
                    AppStrings.noFranchises,
                    AppStrings.noFranchisesAvailable,
                    Icons.business,
                  ),
                ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProspect,
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
                            AppStrings.updateProspect,
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
