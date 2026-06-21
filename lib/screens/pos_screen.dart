import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria_talonario.dart';
import '../models/tipo_talonario.dart';
import '../services/gestor_storage.dart';
import '../utils/currency_formatter.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<TipoTalonario> _tipos = [];
  List<CategoriaTalonario> _categorias = [];
  bool _cargando = true;

  final Map<String, int> _cantidades = {};
  final Map<String, TextEditingController> _cantidadCtrls = {};
  int _efectivo = 0;

  final _tarjetaCtrl = TextEditingController();
  final _manualCtrl = TextEditingController();

  int get _tarjeta =>
      int.tryParse(_tarjetaCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  double get _totalCobrar {
    double total = 0;
    for (final t in _tipos) {
      total += (_cantidades[t.id] ?? 0) * t.precio;
    }
    return total;
  }

  int get _totalBoletos => _cantidades.values.fold(0, (a, b) => a + b);

  double get _totalPagado => _efectivo + _tarjeta.toDouble();

  double get _diferencia => _totalPagado - _totalCobrar;

  @override
  void initState() {
    super.initState();
    _tarjetaCtrl.addListener(() => setState(() {}));
    _cargar();
  }

  Future<void> _cargar() async {
    final cats = await GestorStorage.cargarCategorias();
    final tipos = await GestorStorage.cargarTipos(cats);
    if (!mounted) return;
    setState(() {
      _categorias = cats;
      _tipos = tipos;
      for (final t in tipos) {
        _cantidades.putIfAbsent(t.id, () => 0);
        _cantidadCtrls.putIfAbsent(
          t.id,
          () => TextEditingController(text: '0'),
        );
      }
      _cargando = false;
    });
  }

  void _cambiarCantidad(String id, int delta) {
    setState(() {
      final nuevo = max(0, (_cantidades[id] ?? 0) + delta);
      _cantidades[id] = nuevo;
      final ctrl = _cantidadCtrls[id];
      if (ctrl != null) {
        ctrl.text = nuevo.toString();
        ctrl.selection =
            TextSelection.collapsed(offset: ctrl.text.length);
      }
    });
  }

  void _setCantidadDesdeTexto(String id, String text) {
    final n = max(0, int.tryParse(text) ?? 0);
    setState(() => _cantidades[id] = n);
  }

  void _agregarEfectivo(int amount) => setState(() => _efectivo += amount);

  void _limpiarEfectivo() {
    setState(() => _efectivo = 0);
    _manualCtrl.clear();
  }

  void _agregarManual() {
    final n =
        int.tryParse(_manualCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (n > 0) {
      setState(() => _efectivo += n);
      _manualCtrl.clear();
    }
  }

  void _reiniciar() {
    setState(() {
      for (final id in _cantidades.keys) {
        _cantidades[id] = 0;
        _cantidadCtrls[id]?.text = '0';
      }
      _efectivo = 0;
    });
    _tarjetaCtrl.clear();
    _manualCtrl.clear();
  }

  @override
  void dispose() {
    _tarjetaCtrl.dispose();
    _manualCtrl.dispose();
    for (final ctrl in _cantidadCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final dif = _diferencia;
    final hayActividad = _totalCobrar > 0 || _totalPagado > 0;

    // Agrupar tipos por categoría
    final Map<String, List<TipoTalonario>> grupos = {};
    for (final t in _tipos) {
      grupos.putIfAbsent(t.categoria.id, () => []).add(t);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner FALTANTE / VUELTO
          if (hayActividad) _StatusBanner(diferencia: dif),

          // ─── SECCIÓN BOLETOS ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Boletos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (_totalBoletos > 0)
                  Chip(
                    label: Text(
                      '$_totalBoletos boleto${_totalBoletos != 1 ? "s" : ""}',
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          if (_tipos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay tipos de talonario configurados.\n'
                    'Crea tipos en el Gestor de Talonarios.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            for (final catId in grupos.keys) ...[
              _CategoriaHeader(
                categoria: _categorias.firstWhere(
                  (c) => c.id == catId,
                  orElse: () => CategoriaTalonario.lunesASabado,
                ),
              ),
              Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < grupos[catId]!.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                      _TipoRow(
                        tipo: grupos[catId]![i],
                        cantidad: _cantidades[grupos[catId]![i].id] ?? 0,
                        controller:
                            _cantidadCtrls[grupos[catId]![i].id]!,
                        onMas: () =>
                            _cambiarCantidad(grupos[catId]![i].id, 1),
                        onMenos: () =>
                            _cambiarCantidad(grupos[catId]![i].id, -1),
                        onEditar: (v) =>
                            _setCantidadDesdeTexto(
                              grupos[catId]![i].id,
                              v,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

          // Total a cobrar
          if (_totalCobrar > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.tertiaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Total a cobrar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatPesos(_totalCobrar),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── SECCIÓN PAGO ──────────────────────────────────────────────
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.point_of_sale_outlined,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Método de Pago',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Pago con Tarjeta
          Card(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card_outlined,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pago con Tarjeta',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_tarjeta > 0)
                        Text(
                          formatPesos(_tarjeta.toDouble()),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tarjetaCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ChileanPesoInputFormatter()],
                    decoration: const InputDecoration(
                      hintText: 'Monto con tarjeta',
                      prefixIcon: Icon(Icons.attach_money, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pago en Efectivo
          Card(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pago en Efectivo',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Monedas
                  _SubLabel(label: 'Monedas'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [10, 50, 100, 500]
                        .map(
                          (a) => _MontoChip(
                            amount: a,
                            isCoin: true,
                            onTap: () => _agregarEfectivo(a),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Billetes
                  _SubLabel(label: 'Billetes'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1000, 2000, 5000, 10000, 20000]
                        .map(
                          (a) => _MontoChip(
                            amount: a,
                            isCoin: false,
                            onTap: () => _agregarEfectivo(a),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // Total efectivo + limpiar
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: theme.colorScheme.tertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Efectivo: ${formatPesos(_efectivo.toDouble())}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _limpiarEfectivo,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Ingreso manual
                  _SubLabel(label: 'Ingreso Manual de Efectivo'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _manualCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ChileanPesoInputFormatter()],
                          decoration: const InputDecoration(
                            hintText: 'Monto Manual',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.keyboard, size: 18),
                          ),
                          onFieldSubmitted: (_) => _agregarManual(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _agregarManual,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Resumen de pago
          if (hayActividad)
            _ResumenPago(
              totalCobrar: _totalCobrar,
              efectivo: _efectivo.toDouble(),
              tarjeta: _tarjeta.toDouble(),
              diferencia: dif,
            ),

          // Botón nueva venta
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: OutlinedButton.icon(
              onPressed: _reiniciar,
              icon: const Icon(Icons.refresh),
              label: const Text('Nueva Venta'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internos ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final double diferencia;
  const _StatusBanner({required this.diferencia});

  @override
  Widget build(BuildContext context) {
    final esVuelto = diferencia >= 0;
    final color =
        esVuelto ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bg =
        esVuelto ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            esVuelto ? 'VUELTO:' : 'FALTANTE:',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            formatPesos(diferencia.abs()),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriaHeader extends StatelessWidget {
  final CategoriaTalonario categoria;
  const _CategoriaHeader({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: categoria.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Boletos ${categoria.nombre}',
            style: TextStyle(
              color: categoria.color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoRow extends StatelessWidget {
  final TipoTalonario tipo;
  final int cantidad;
  final TextEditingController controller;
  final VoidCallback onMas;
  final VoidCallback onMenos;
  final ValueChanged<String> onEditar;

  const _TipoRow({
    required this.tipo,
    required this.cantidad,
    required this.controller,
    required this.onMas,
    required this.onMenos,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = cantidad * tipo.precio;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Info boleto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tipo.categoria.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tipo.categoria.nombre,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tipo.categoria.color,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatPesos(tipo.precio),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (cantidad > 0)
                  Text(
                    'Subtotal: ${formatPesos(subtotal)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          // Selector cantidad
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BotonCantidad(
                icon: Icons.remove,
                onPressed: onMenos,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: onEditar,
                ),
              ),
              const SizedBox(width: 6),
              _BotonCantidad(
                icon: Icons.add,
                onPressed: onMas,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  const _BotonCantidad({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _MontoChip extends StatelessWidget {
  final int amount;
  final bool isCoin;
  final VoidCallback onTap;

  const _MontoChip({
    required this.amount,
    required this.isCoin,
    required this.onTap,
  });

  Color get _color {
    if (isCoin) return const Color(0xFFF59E0B);
    switch (amount) {
      case 1000:
        return const Color(0xFF388E3C);
      case 2000:
        return const Color(0xFF7B1FA2);
      case 5000:
        return const Color(0xFFE91E8C);
      case 10000:
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFFE65100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = formatNumber(amount);
    final icon =
        isCoin ? Icons.monetization_on_outlined : Icons.receipt_outlined;

    return Material(
      color: _color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '$label \$',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String label;
  const _SubLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ResumenPago extends StatelessWidget {
  final double totalCobrar;
  final double efectivo;
  final double tarjeta;
  final double diferencia;

  const _ResumenPago({
    required this.totalCobrar,
    required this.efectivo,
    required this.tarjeta,
    required this.diferencia,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esVuelto = diferencia >= 0;
    final difColor =
        esVuelto ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Resumen de Pago',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _FilaResumen(
              label: 'Total a cobrar',
              valor: formatPesos(totalCobrar),
              color: theme.colorScheme.onSurfaceVariant,
            ),
            if (tarjeta > 0) ...[
              const SizedBox(height: 4),
              _FilaResumen(
                label: 'Tarjeta',
                valor: formatPesos(tarjeta),
                color: theme.colorScheme.secondary,
              ),
            ],
            if (efectivo > 0) ...[
              const SizedBox(height: 4),
              _FilaResumen(
                label: 'Efectivo',
                valor: formatPesos(efectivo),
                color: theme.colorScheme.tertiary,
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  esVuelto ? 'VUELTO' : 'FALTANTE',
                  style: TextStyle(
                    color: difColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  formatPesos(diferencia.abs()),
                  style: TextStyle(
                    color: difColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _FilaResumen({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        Text(
          valor,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
