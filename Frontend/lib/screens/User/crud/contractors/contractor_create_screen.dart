import 'package:flutter/material.dart';
// import 'package:logger/web.dart';
import 'package:vnet_agenda/services/authentication/auth_service.dart';
import 'package:vnet_agenda/services/crud/contractor_services.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';

class ContractorCreateScreen extends StatefulWidget {
  const ContractorCreateScreen({super.key});

  @override
  State<ContractorCreateScreen> createState() => _ContractorCreateScreenState();
}

//Logger _logger = Logger();

class _ContractorCreateScreenState extends State<ContractorCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Debug
  // final Logger _logger = Logger();

  // Servicios
  final ContractorServices _contractorService = ContractorServices();
  final FranchiseService _franchiseService = FranchiseService();
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _rifController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Catálogos
  List<Map<String, dynamic>> _franchises = [];
  bool _loadingFranchises = false;

  // Selecciones
  String? _selectedFranchiseId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFranchises().then((_) => _initUserData());
  }

  // Variablles
  int? _roleId;
  String? _userFranchiseId;

  Future<void> _loadFranchises() async {
    setState(() => _loadingFranchises = true);
    try {
      final data = await _franchiseService.getAllFranchises();
      setState(() => _franchises = data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar las ciudades')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingFranchises = false);
    }
  }

  Future<void> _initUserData() async {
    final data = await _authService.getDataUserRoleFranchise();
    _roleId = int.parse(data['role']);
    _userFranchiseId = data['franchise'].toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFranchiseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una ciudad')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final payload = <String, dynamic>{
        'legal_name': _legalNameController.text.trim(),
        'rif': _rifController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'franchise_id': int.parse(_selectedFranchiseId!),
        'address': _addressController.text.trim(),
      };

      await _contractorService.createContractor(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contratista creado exitosamente'),
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
      appBar: AppBar(title: const Text('Crear contratista')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _section('Datos del contratista'),
                _textField(
                  controller: _legalNameController,
                  label: 'Razón Social',
                  required: true,
                  maxLen: 255,
                ),
                _textField(
                  controller: _rifController,
                  label: 'RIF',
                  required: true,
                  maxLen: 20,
                  textCapitalization: TextCapitalization.characters,
                ),
                _textField(
                  controller: _nameController,
                  label: 'Nombre de contacto',
                  required: true,
                  maxLen: 255,
                ),
                _textField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  required: true,
                  maxLen: 20,
                  keyboard: TextInputType.phone,
                ),
                _textField(
                  controller: _emailController,
                  label: 'Email',
                  required: true,
                  maxLen: 255,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    final ok = RegExp(
                      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
                    ).hasMatch(v);
                    if (!ok) return 'Email inválido';
                    return null;
                  },
                ),
                _textField(
                  controller: _addressController,
                  label: 'Dirección',
                  required: true,
                  maxLen: 255,
                ),
                const SizedBox(height: 12),
                _section('Ciudad'),
                _franchiseDropdown(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon:
                        _submitting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool obscure = false,
    int? maxLen,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        obscureText: obscure,
        keyboardType: keyboard,
        textCapitalization: textCapitalization,
        maxLength: maxLen,
        validator:
            validator ??
            (v) {
              if (required && (v == null || v.isEmpty)) {
                return 'Campo requerido';
              }
              if (maxLen != null && v != null && v.length > maxLen) {
                return 'Máximo $maxLen caracteres';
              }
              return null;
            },
      ),
    );
  }

  Widget _franchiseDropdown() {
    if (_loadingFranchises) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_roleId == 1) {
      final value =
          _franchises.any((f) => f['id'].toString() == _selectedFranchiseId)
              ? _selectedFranchiseId
              : null;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DropdownButtonFormField<String>(
          value: value,
          items:
              _franchises
                  .map(
                    (f) => DropdownMenuItem<String>(
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
          validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
        ),
      );
    } else {
      final franchiseName =
          _franchises.firstWhere(
            (f) => f['id'].toString() == _userFranchiseId,
            orElse: () => <String, dynamic>{'name': 'Ciudad no encontrada'},
          )['name'];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: TextEditingController(text: franchiseName.toString()),
          decoration: const InputDecoration(
            labelText: 'Ciudad',
            border: OutlineInputBorder(),
          ),
          readOnly: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _rifController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
