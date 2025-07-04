import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend_clinicasa/models/user.dart';
import 'package:frontend_clinicasa/models/address.dart';
import 'package:frontend_clinicasa/services/register_service.dart';

class AddressScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AddressScreen({super.key, required this.userData});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _complementoController = TextEditingController();
  bool _isLoadingCep = false;
  String? _cepError;
  String _lastCepValue = '';

  @override
  void dispose() {
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  void _onCepChanged(String value) {
    // Máscara: 00000-000
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    String formatted = '';
    if (digits.length >= 5) {
      formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
    } else {
      formatted = digits;
    }
    if (formatted != value) {
      _cepController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (digits.length == 8 && _lastCepValue != digits) {
      _lastCepValue = digits;
      _buscarCep(formatted);
    }
  }

  Future<void> _buscarCep(String cep) async {
    setState(() {
      _isLoadingCep = true;
      _cepError = null;
    });
    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanCep.length != 8) {
        setState(() {
          _cepError = 'CEP deve ter 8 dígitos';
          _isLoadingCep = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == true) {
          setState(() {
            _cepError = 'CEP não encontrado';
            _ruaController.clear();
            _bairroController.clear();
          });
        } else {
          setState(() {
            _ruaController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _estadoController.text = data['uf'] ?? '';
          });
        }
      } else {
        setState(() {
          _cepError = 'Erro ao buscar CEP';
        });
      }
    } catch (e) {
      setState(() {
        _cepError = 'Erro ao buscar CEP';
      });
    } finally {
      setState(() {
        _isLoadingCep = false;
      });
    }
  }

  String? _validateCep(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite o CEP';
    }
    final cleanCep = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    if (_cepError != null) {
      return _cepError;
    }
    return null;
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.isEmpty) {
      return 'Digite $field';
    }
    return null;
  }

  String? _validateNumero(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite o número';
    }
    if (!RegExp(r'^\d+ ?$').hasMatch(value)) {
      return 'Digite apenas números';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Prosseguir para a próxima etapa
      // Exemplo: Navigator.of(context).pushNamed('/next_step');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF217346),
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Endereço',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CEP',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cepController,
                          decoration: InputDecoration(
                            hintText: '00000-000',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: _isLoadingCep
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateCep,
                          onChanged: (value) {
                            final digits = value.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (digits.length == 8 && digits != _lastCepValue) {
                              _lastCepValue = digits;
                              _buscarCep(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rua',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ruaController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: Rua das Flores',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) =>
                              _validateRequired(value, 'a rua'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Número',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _numeroController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: 92',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateNumero,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bairro',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _bairroController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: Bairro da Silva',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) =>
                              _validateRequired(value, 'o bairro'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cidade',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cidadeController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: São Paulo',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) =>
                              _validateRequired(value, 'a cidade'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Estado',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _estadoController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: SP',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) =>
                              _validateRequired(value, 'o estado'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complemento (opcional)',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _complementoController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: Apto 101',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final address = Address(
                  street: _ruaController.text,
                  number: _numeroController.text,
                  neighborhood: _bairroController.text,
                  city: _cidadeController.text,
                  state: _estadoController.text,
                  zipcode: _cepController.text,
                  complement: _complementoController.text.isEmpty
                      ? null
                      : _complementoController.text,
                );
                final user = User(
                  name: widget.userData['name'],
                  gender: widget.userData['gender'],
                  phone: widget.userData['phone'],
                  email: widget.userData['email'],
                  password: widget.userData['password'],
                  accountType: widget.userData['accountType'],
                );
                try {
                  await RegisterService.registerUser(
                    user: user,
                    address: address,
                  );
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/register_confirmation');
                } catch (e) {
                  String errorMessage = 'Erro ao cadastrar';
                  if (e.toString().contains('EMAIL_DUPLICADO')) {
                    errorMessage = 'Este e-mail já está cadastrado';
                  } else if (e.toString().contains('Dados inválidos')) {
                    errorMessage = 'Verifique os dados fornecidos';
                  }
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Erro'),
                      content: Text(errorMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Finalizar cadastro'),
          ),
        ),
      ),
    );
  }
}
