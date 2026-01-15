import 'package:flutter/material.dart';
import 'package:vnet_agenda/services/crud/user_services.dart';
import 'package:vnet_agenda/services/others/franchise_service.dart';
import 'package:vnet_agenda/services/others/role_service.dart';

class UserEditScreen extends StatefulWidget {
  final String? userId;
  const UserEditScreen({super.key, this.userId});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Servicios
  final UserServices _userService = UserServices();
  final FranchiseService _franchiseService = FranchiseService();
  final RoleService _roleService = RoleService();

  // Controllers
  final TextEditingController _aradialUserIdController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _documentTypeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _contractorIdController = TextEditingController();

  // Catálogos y selección
  List<Map<String, dynamic>> _franchises = [];
  List<Map<String, dynamic>> _roles = [];
  bool _loadingFranchises = false;
  bool _loadingRoles = false;
  String? _selectedFranchiseId;
  String? _selectedRoleId;

  // Estado
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId == null) {
      // Si no pasan un id, no intentamos cargar detalles para no romper navegación existente
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
      await Future.wait([_loadFranchises(), _loadRoles()]);
      await _loadUser();
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
      setState(() {
        _franchises = data;
        _franchises = data.map((e) => e).toList();
        _franchises.sort((a, b) {
          String nombreA = a['branch_office']?.toString().toLowerCase() ?? '';
          String nombreB = b['branch_office']?.toString().toLowerCase() ?? '';

          return nombreA.compareTo(nombreB);
        });
      });
    } catch (_) {
      // ya se notifica en UI si falla general
    } finally {
      if (mounted) setState(() => _loadingFranchises = false);
    }
  }

  Future<void> _loadRoles() async {
    setState(() => _loadingRoles = true);
    try {
      final data = await _roleService.getAllRole();
      setState(() => _roles = data);
    } catch (_) {
      // ya se notifica en UI si falla general
    } finally {
      if (mounted) setState(() => _loadingRoles = false);
    }
  }

  Future<void> _loadUser() async {
    if (widget.userId == null) return;
    final u = await _userService.getUserDetails(widget.userId!);

    // Setear controllers y selecciones
    _aradialUserIdController.text = (u['aradial_user_id'] ?? '').toString();
    _nameController.text = (u['name'] ?? '').toString();
    _lastNameController.text = (u['last_name'] ?? '').toString();
    _documentController.text = (u['document'] ?? '').toString();
    _documentTypeController.text = (u['document_type'] ?? '').toString();
    _phoneController.text = (u['phone'] ?? '').toString();
    _emailController.text = (u['email'] ?? '').toString();

    _selectedFranchiseId = (u['franchise_id'] ?? '').toString();
    _selectedRoleId = (u['role_id'] ?? '').toString();

    final contractorId = u['contractor_id'];
    if (contractorId != null) {
      _contractorIdController.text = contractorId.toString();
    }

    if (mounted) setState(() {});
  }

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

    if (_isEmployee) {
      if (_contractorIdController.text.isEmpty ||
          int.tryParse(_contractorIdController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe indicar un contractor_id válido')),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final payload = <String, dynamic>{
        'aradial_user_id': _aradialUserIdController.text.trim(),
        'name': _nameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'document': _documentController.text.trim(),
        'document_type': _documentTypeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'franchise_id': int.parse(_selectedFranchiseId!),
        'role_id': int.parse(_selectedRoleId!),
        'email': _emailController.text.trim(),
      };

      // Password opcional
      if (_newPasswordController.text.isNotEmpty) {
        payload['password'] = _newPasswordController.text;
      }

      if (_isEmployee) {
        payload['contractor_id'] = int.parse(_contractorIdController.text);
      } else {
        // Si no aplica, explícitamente mandar null para borrar vínculo si backend lo permite
        payload['contractor_id'] = null;
      }

      if (widget.userId == null) {
        // Sin id no se puede actualizar, solo informamos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede actualizar: id no provisto'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _userService.updateUser(widget.userId!, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario actualizado'),
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
    if (widget.userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar usuario')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'ID de usuario no provisto. Vuelva al listado para seleccionar un usuario.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar usuario')),
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
                        _section('Datos de usuario'),
                        _textField(
                          controller: _aradialUserIdController,
                          label: 'Aradial User ID',
                          required: true,
                          maxLen: 100,
                        ),
                        _textField(
                          controller: _nameController,
                          label: 'Nombre',
                          required: true,
                          maxLen: 50,
                        ),
                        _textField(
                          controller: _lastNameController,
                          label: 'Apellido',
                          required: true,
                          maxLen: 50,
                        ),
                        _textField(
                          controller: _documentController,
                          label: 'Documento',
                          required: true,
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _documentTypeController,
                          label: 'Tipo de Documento',
                          required: true,
                          maxLen: 20,
                        ),
                        _textField(
                          controller: _phoneController,
                          label: 'Teléfono',
                          required: true,
                          maxLen: 20,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _section('Cuenta'),
                        _textField(
                          controller: _emailController,
                          label: 'Email',
                          required: true,
                          maxLen: 255,
                          keyboard: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo requerido';
                            }
                            final ok = RegExp(
                              r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
                            ).hasMatch(v);
                            if (!ok) return 'Email inválido';
                            return null;
                          },
                        ),
                        _textField(
                          controller: _newPasswordController,
                          label: 'Nueva contraseña (opcional)',
                          required: false,
                          obscure: true,
                          maxLen: 100,
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 8) {
                              return 'Debe tener al menos 8 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _section('Franquicia y Rol'),
                        _franchiseDropdown(),
                        _roleDropdown(),
                        if (_isEmployee) _employeeSection(),
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

  Widget _roleDropdown() {
    if (_loadingRoles) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final value =
        _roles.any((r) => r['id'].toString() == _selectedRoleId)
            ? _selectedRoleId
            : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            _roles.map((r) {
              final id = r['id']?.toString() ?? '';
              final name = (r['name'] ?? r['role_name'] ?? 'Rol').toString();
              return DropdownMenuItem<String>(value: id, child: Text(name));
            }).toList(),
        onChanged: (v) => setState(() => _selectedRoleId = v),
        decoration: const InputDecoration(
          labelText: 'Rol',
          border: OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
      ),
    );
  }

  Widget _employeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Asignación de Contratista (solo si aplica)'),
        _textField(
          controller: _contractorIdController,
          label: 'Contractor ID',
          required: true,
          maxLen: 10,
          keyboard: TextInputType.number,
          validator: (v) {
            if (!_isEmployee) return null; // Solo valida si aplica
            if (v == null || v.isEmpty) return 'Campo requerido';
            if (int.tryParse(v) == null) return 'Debe ser numérico';
            return null;
          },
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
    _documentTypeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _contractorIdController.dispose();
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
