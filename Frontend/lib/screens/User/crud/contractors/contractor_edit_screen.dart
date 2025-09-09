import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/contractor_services.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/strings/app_strings.dart';

class ContractorEditScreen extends StatefulWidget {
  final String? contractorId;
  const ContractorEditScreen({super.key, this.contractorId});

  @override
  State<ContractorEditScreen> createState() => _ContractorEditScreenState();
}

class _ContractorEditScreenState extends State<ContractorEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Servicios
  final ContractorService _contractorService = ContractorService();
  final FranchiseService _franchiseService = FranchiseService();

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
  String? _selectedFranchiseId;

  // Estado
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.contractorId == null) {
      _loading = false;
    } else {
      _initLoad();
    }
  }

  Future<void> _initLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadFranchises();
      await _loadContractor();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFranchises() async {
    setState(() => _loadingFranchises = true);
    try {
      final data = await _franchiseService.getAllFranchises();
      setState(() => _franchises = data);
    } catch (_) {
      // Manejo ya en _initLoad
    } finally {
      if (mounted) setState(() => _loadingFranchises = false);
    }
  }

  Future<void> _loadContractor() async {
    if (widget.contractorId == null) return;
    final c = await _contractorService.getContractorDetails(
      widget.contractorId!,
    );

    _legalNameController.text = (c['legal_name'] ?? '').toString();
    _rifController.text = (c['rif'] ?? '').toString();
    _nameController.text = (c['name'] ?? '').toString();
    _phoneController.text = (c['phone'] ?? '').toString();
    _emailController.text = (c['email'] ?? '').toString();
    _addressController.text = (c['address'] ?? '').toString();
    _selectedFranchiseId = (c['franchise_id'] ?? '').toString();

    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFranchiseId == null || _selectedFranchiseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una franquicia')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      if (widget.contractorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede actualizar: id no provisto'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final payload = <String, dynamic>{
        'legal_name': _legalNameController.text.trim(),
        'rif': _rifController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'franchise_id': int.parse(_selectedFranchiseId!),
        'address': _addressController.text.trim(),
      };

      await _contractorService.updateContractor(widget.contractorId!, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contratista actualizado'),
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
    if (widget.contractorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar contratista')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'ID de contratista no provisto. Vuelva al listado para seleccionar un contratista.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar contratista')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorView(message: _error!, onRetry: _initLoad)
              : SafeArea(
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
                        _textField(
                          controller: _addressController,
                          label: 'Dirección',
                          required: true,
                          maxLen: 255,
                        ),
                        const SizedBox(height: 12),
                        _section('Franquicia'),
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
                            label: const Text('Guardar cambios'),
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
          labelText: 'Franquicia',
          border: OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
      ),
    );
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
