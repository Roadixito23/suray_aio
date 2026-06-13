import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/resultado_calculo.dart';
import '../services/gestor_storage.dart';

class TalonarioForm extends StatefulWidget {
  final void Function(ResultadoCalculo) onCalcular;

  const TalonarioForm({super.key, required this.onCalcular});

  @override
  State<TalonarioForm> createState() => _TalonarioFormState();
}

class _TalonarioFormState extends State<TalonarioForm> {
  final _formKey = GlobalKey<FormState>();
  final _precioCtrl = TextEditingController();
  final _primerCtrl = TextEditingController();
  final _ultimoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _precioCtrl.addListener(_guardarBorrador);
    _primerCtrl.addListener(_guardarBorrador);
    _ultimoCtrl.addListener(_guardarBorrador);
    _cargarBorrador();
  }

  Future<void> _cargarBorrador() async {
    final borrador = await GestorStorage.cargarBorradorCalculadora();
    if (!mounted) return;
    if (borrador['precio']!.isNotEmpty) _precioCtrl.text = borrador['precio']!;
    if (borrador['primer']!.isNotEmpty) _primerCtrl.text = borrador['primer']!;
    if (borrador['ultimo']!.isNotEmpty) _ultimoCtrl.text = borrador['ultimo']!;
  }

  void _guardarBorrador() {
    GestorStorage.guardarBorradorCalculadora(
      precio: _precioCtrl.text,
      primer: _primerCtrl.text,
      ultimo: _ultimoCtrl.text,
    ).ignore();
  }

  @override
  void dispose() {
    _precioCtrl.removeListener(_guardarBorrador);
    _primerCtrl.removeListener(_guardarBorrador);
    _ultimoCtrl.removeListener(_guardarBorrador);
    _precioCtrl.dispose();
    _primerCtrl.dispose();
    _ultimoCtrl.dispose();
    super.dispose();
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;

    final precio = double.parse(_precioCtrl.text.replaceAll(',', '.'));
    final primer = int.parse(_primerCtrl.text);
    final ultimo = int.parse(_ultimoCtrl.text);

    widget.onCalcular(
      ResultadoCalculo.calcular(
        precioPorBoleto: precio,
        primerTalonario: primer,
        ultimoTalonario: ultimo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NumField(
            controller: _precioCtrl,
            label: 'Precio por boleto (\$)',
            icon: Icons.attach_money,
            decimal: true,
            validator: _validarDecimal,
          ),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Rango vendido', theme: theme),
          Row(
            children: [
              Expanded(
                child: _NumField(
                  controller: _primerCtrl,
                  label: 'Primer talonario',
                  icon: Icons.first_page,
                  validator: (v) => _validarEntero(v, min: 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumField(
                  controller: _ultimoCtrl,
                  label: 'Último talonario',
                  icon: Icons.last_page,
                  validator: (v) {
                    final base = _validarEntero(v, min: 0);
                    if (base != null) return base;
                    final primer = int.tryParse(_primerCtrl.text);
                    final ultimo = int.tryParse(v ?? '');
                    if (primer != null && ultimo != null && ultimo < primer) {
                      return 'Debe ser ≥ al primero';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  String? _validarEntero(String? value, {required int min}) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    final n = int.tryParse(value);
    if (n == null) return 'Ingresá un número entero';
    if (n < min) return 'Debe ser mayor a ${min - 1}';
    return null;
  }

  String? _validarDecimal(String? value) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null) return 'Ingresá un número válido';
    if (n <= 0) return 'Debe ser mayor a 0';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool decimal;
  final String? Function(String?)? validator;

  const _NumField({
    required this.controller,
    required this.label,
    required this.icon,
    this.decimal = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[\d,.]') : RegExp(r'\d'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: validator,
    );
  }
}
