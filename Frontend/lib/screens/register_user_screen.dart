import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/contractor_services.dart';
import 'package:vnet_agenda/services/others/register_service_user.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/services/others/role_service.dart';
import 'package:vnet_agenda/services/others/contractor_service.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();

  // Servicios
  final FranchiseService _franchiseService = FranchiseService();
  final RoleService _roleService = RoleService();
  final RegisterServiceUser _registerService = RegisterServiceUser();
  final ContractorService _contractorService = ContractorService();
  final ContractorServices _contractorServices = ContractorServices();
  final AuthService _authService =
      AuthService(); // Agregar instancia de AuthService

  // Controllers de usuario
  final TextEditingController _aradialUserIdController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Controllers de contratista (role_id == 3)
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _rifController = TextEditingController();
  final TextEditingController _contractorNameController =
      TextEditingController();
  final TextEditingController _contractorPhoneController =
      TextEditingController();
  final TextEditingController _contractorEmailController =
      TextEditingController();
  final TextEditingController _contractorAddressController =
      TextEditingController();

  // Contractor para role_id == 4 (empleado)
  final TextEditingController _contractorIdController = TextEditingController();

  // Catálogos
  List<Map<String, dynamic>> _franchises = [];
  bool _loadingFranchises = false;
  List<Map<String, dynamic>> _roles = [];
  bool _loadingRoles = false;
  List<Map<String, dynamic>> _contractors = [];
  bool _loadingContractors = false;

  // Selecciones
  String? _selectedFranchiseId;
  String? _selectedRoleId;
  String? _selectedContractorId;
  String? _selectedTypeDocument; // para empleados

  bool _submitting = false;

  // Agregar variable para el rol del usuario actual
  String? _currentUserRoleId;

  final List<Map<String, String>> _docTypes = [
    {'value': 'V', 'label': 'V - Venezolano'},
    {'value': 'E', 'label': 'E - Extranjero'},
    {'value': 'J', 'label': 'J - Jurídico'},
    {'value': 'G', 'label': 'G - Gobierno'},
    {'value': 'P', 'label': 'P - Pasaporte'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFranchises();
    _loadRoles();
    _loadCurrentUserRole();
  }

  // Agregar método para cargar el rol del usuario actual
  Future<void> _loadCurrentUserRole() async {
    try {
      // Asumir que AuthService tiene un método getUserRoleId() que devuelve el ID del rol como String
      _currentUserRoleId = await _authService.getUserRole();
      setState(() {});
    } catch (e) {
      // Manejar error si es necesario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar rol del usuario: $e')),
        );
      }
    }
  }

  Future<void> _loadFranchises() async {
    setState(() => _loadingFranchises = true);
    try {
      final data = await _franchiseService.getAllFranchises();
      setState(() {
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

  Future<void> _loadRoles() async {
    setState(() => _loadingRoles = true);
    try {
      final data = await _roleService.getAllRole();
      setState(() {
        _roles = data.map((e) => e).toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar los roles')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRoles = false);
    }
  }

  Future<void> _loadContractors() async {
    setState(() => _loadingContractors = true);
    try {
      final data = await _contractorService.getAllContractor();
      setState(() {
        _contractors = data;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar los contratistas'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingContractors = false);
    }
  }

  bool get _isContractor => _selectedRoleId == '3';
  bool get _isEmployee => _selectedRoleId == '4';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFranchiseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una franquicia')),
      );
      return;
    }

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debe seleccionar un rol')));
      return;
    }

    // Validaciones específicas para contratistas
    if (_isContractor) {
      if (_legalNameController.text.isEmpty ||
          _rifController.text.isEmpty ||
          _contractorAddressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete los datos del contratista')),
        );
        return;
      }
    }

    // Validaciones específicas para empleados
    if (_isEmployee) {
      if (_selectedContractorId == null ||
          int.tryParse(_selectedContractorId!) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar un contratista válido'),
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      // Crear contratista si el rol es 3
      String? contractorId;
      if (_isContractor) {
        final contractorPayload = {
          'legal_name': _legalNameController.text.trim(),
          'rif': _rifController.text.trim(),
          'name': _contractorNameController.text.trim(),
          'phone': _contractorPhoneController.text.trim(),
          'email': _contractorEmailController.text.trim(),
          'address': _contractorAddressController.text.trim(),
          'franchise_id': int.parse(_selectedFranchiseId!),
        };

        final contractor = await _contractorServices.createContractor(
          contractorPayload,
        );
        contractorId = contractor['id'].toString();
      }

      // Crear usuario
      final userPayload = {
        'aradial_user_id': _aradialUserIdController.text.trim(),
        'name': _nameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'document': _documentController.text.trim(),
        'document_type': _selectedTypeDocument ?? 'V',
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'role_id': int.parse(_selectedRoleId!),
        'franchise_id': int.parse(_selectedFranchiseId!),
        if (contractorId != null) 'contractor_id': int.parse(contractorId),
        if (_isEmployee) 'contractor_id': int.parse(_selectedContractorId!),
      };

      await _registerService.createUser(userPayload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _sectionTitle('Datos de Usuario'),
                _textField(
                  _aradialUserIdController,
                  'Aradial User ID',
                  maxLen: 50,
                  required: true,
                ),
                _textField(
                  _nameController,
                  'Nombre',
                  maxLen: 255,
                  required: true,
                ),
                _textField(
                  _lastNameController,
                  'Apellido',
                  maxLen: 255,
                  required: true,
                ),
                _textField(
                  _documentController,
                  'Documento',
                  maxLen: 50,
                  required: true,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedTypeDocument,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Documento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  items:
                      _docTypes.map((docType) {
                        return DropdownMenuItem<String>(
                          value: docType['value'],
                          child: Text(docType['label']!),
                        );
                      }).toList(),
                  onChanged:
                      (value) => setState(() => _selectedTypeDocument = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccione un tipo de documento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _textField(
                  _phoneController,
                  'Teléfono',
                  maxLen: 20,
                  required: true,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _sectionTitle('Cuenta'),
                _textField(
                  _emailController,
                  'Email',
                  maxLen: 255,
                  required: true,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    final ok = RegExp(
                      r'^[\w-\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v);
                    if (!ok) return 'Email inválido';
                    return null;
                  },
                ),
                _textField(
                  _passwordController,
                  'Password',
                  maxLen: 100,
                  required: true,
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _sectionTitle('Ciudad y Tipo de usuario'),
                _franchiseDropdown(),
                const SizedBox(height: 12),
                _roleDropdown(),
                const SizedBox(height: 12),
                if (_isContractor) _contractorSection(),
                if (_isEmployee) _employeeSection(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child:
                        _submitting
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _textField(
    TextEditingController c,
    String label, {
    int maxLen = 255,
    bool required = false,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        obscureText: obscure,
        keyboardType: keyboard,
        maxLength: maxLen,
        validator:
            validator ??
            (v) {
              if (required && (v == null || v.isEmpty)) {
                return 'Campo requerido';
              }
              if (v != null && v.length > maxLen) {
                return 'Máximo $maxLen caracteres';
              }
              return null;
            },
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
      value: _selectedFranchiseId,
      items:
          _franchises
              .map(
                (f) => DropdownMenuItem(
                  value: f['id'].toString(),
                  child: Text(
                    (f['branch_office'] ?? f['name'] ?? 'Franquicia')
                        .toString(),
                  ),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _selectedFranchiseId = v),
      decoration: const InputDecoration(
        labelText: 'Ciudad',
        border: OutlineInputBorder(),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _roleDropdown() {
    if (_loadingRoles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    // Filtrar roles basado en el rol del usuario actual
    List<Map<String, dynamic>> filteredRoles = _roles;
    if (_currentUserRoleId == '1') {
      // Mostrar todos los roles
      filteredRoles = _roles;
    } else if (_currentUserRoleId == '2') {
      // Mostrar solo "Cuadrilla" y "Contratista"
      filteredRoles =
          _roles.where((r) {
            final name = (r['name'] ?? '').toString().toLowerCase();
            return name.contains('cuadrilla') || name.contains('contratista');
          }).toList();
    }
    // Para otros roles, mostrar todos o ninguno, según lógica adicional si es necesario

    return DropdownButtonFormField<String>(
      value: _selectedRoleId,
      items:
          filteredRoles.map((r) {
            final id = r['id']?.toString() ?? '';
            final name = (r['name'] ?? r['role_name'] ?? 'Rol').toString();
            return DropdownMenuItem(value: id, child: Text(name));
          }).toList(),
      onChanged: (v) {
        setState(() {
          _selectedRoleId = v;
          _selectedContractorId = null;
        });
        if (_isEmployee) {
          _loadContractors();
        }
      },
      decoration: const InputDecoration(
        labelText: 'Tipo Usuario',
        border: OutlineInputBorder(),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _contractorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Datos del Contratista (Rol Contratista)'),
        _textField(
          _legalNameController,
          'Razón Social',
          maxLen: 50,
          required: true,
        ),
        _textField(_rifController, 'RIF', maxLen: 20, required: true),
        _textField(
          _contractorNameController,
          'Nombre Contacto (opcional)',
          maxLen: 20,
        ),
        _textField(
          _contractorPhoneController,
          'Teléfono Empresa (opcional)',
          maxLen: 20,
          keyboard: TextInputType.phone,
        ),
        _textField(
          _contractorEmailController,
          'Email Empresa (opcional)',
          maxLen: 100,
          keyboard: TextInputType.emailAddress,
        ),
        _textField(
          _contractorAddressController,
          'Dirección Empresa',
          maxLen: 250,
          required: true,
        ),
      ],
    );
  }

  Widget _employeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Asignación de Contratista (Rol Empleado)'),
        if (_loadingContractors)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedContractorId,
            items:
                _contractors
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(
                          (c['legal_name'] ?? 'Contratista').toString(),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (v) => setState(() => _selectedContractorId = v),
            decoration: const InputDecoration(
              labelText: 'Contratista',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (!_isEmployee) return null;
              return (v == null || v.isEmpty) ? 'Campo requerido' : null;
            },
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _loadContractors,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar contratistas'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _aradialUserIdController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _legalNameController.dispose();
    _rifController.dispose();
    _contractorNameController.dispose();
    _contractorPhoneController.dispose();
    _contractorEmailController.dispose();
    _contractorAddressController.dispose();

    _contractorIdController.dispose();
    super.dispose();
  }
}
