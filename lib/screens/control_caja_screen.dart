import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/control_caja.dart';
import '../models/tipo_talonario.dart';
import '../services/gestor_storage.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String _fmtFechaHora(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

// ─── Entrada de rango (runtime, no persistida) ────────────────────────────────

class _RangoEntry {
  final TextEditingController desdeCtrl = TextEditingController();
  final TextEditingController hastaCtrl = TextEditingController();

  void dispose() {
    desdeCtrl.dispose();
    hastaCtrl.dispose();
  }

  int? get desde => int.tryParse(desdeCtrl.text.trim());
  int? get hasta => int.tryParse(hastaCtrl.text.trim());
  bool get ambosLlenos => desdeCtrl.text.trim().isNotEmpty && hastaCtrl.text.trim().isNotEmpty;
  bool get esValido => desde != null && hasta != null && hasta! >= desde!;
  bool get hayError => ambosLlenos && !esValido;
  int get boletos => esValido ? hasta! - desde! + 1 : 0;
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class ControlCajaScreen extends StatefulWidget {
  const ControlCajaScreen({super.key});

  @override
  State<ControlCajaScreen> createState() => _ControlCajaScreenState();
}

class _ControlCajaScreenState extends State<ControlCajaScreen> {
  List<TipoTalonario> _tipos = [];
  List<List<_RangoEntry>> _rangos = [];
  DateTime _fecha = DateTime.now();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final lista in _rangos) {
      for (final r in lista) {
        r.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    final categorias = await GestorStorage.cargarCategorias();
    final tipos = await GestorStorage.cargarTipos(categorias);
    if (!mounted) return;
    setState(() {
      _tipos = tipos;
      _rangos = List.generate(tipos.length, (_) => [_RangoEntry()]);
      _loaded = true;
    });
  }

  void _agregarRango(int tipoIdx) {
    setState(() => _rangos[tipoIdx].add(_RangoEntry()));
  }

  void _eliminarRango(int tipoIdx, int rangoIdx) {
    final entry = _rangos[tipoIdx][rangoIdx];
    setState(() => _rangos[tipoIdx].removeAt(rangoIdx));
    entry.dispose();
  }

  double _subtotalTipo(int i) =>
      _rangos[i].fold(0.0, (s, r) => s + r.boletos * _tipos[i].precio);

  double get _total =>
      List.generate(_tipos.length, _subtotalTipo).fold(0.0, (a, b) => a + b);

  int get _totalBoletos => _rangos
      .expand((lista) => lista)
      .fold(0, (s, r) => s + r.boletos);

  bool get _hayErrores =>
      _rangos.expand((lista) => lista).any((r) => r.hayError);

  void _limpiar() {
    setState(() {
      for (final lista in _rangos) {
        for (final r in lista) {
          r.dispose();
        }
      }
      _rangos = List.generate(_tipos.length, (_) => [_RangoEntry()]);
    });
  }

  Future<void> _guardar() async {
    if (_hayErrores) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corregí los rangos inválidos antes de guardar')),
      );
      return;
    }
    if (_totalBoletos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá al menos un rango válido')),
      );
      return;
    }

    final lineas = <ControlCajaLinea>[];
    for (int i = 0; i < _tipos.length; i++) {
      final rangosValidos = _rangos[i].where((r) => r.esValido).toList();
      if (rangosValidos.isEmpty) continue;
      lineas.add(ControlCajaLinea(
        tipoId: _tipos[i].id,
        descripcion: '${_tipos[i].boletos} bol × ${formatPesos(_tipos[i].precio)}',
        categoriaNombre: _tipos[i].categoria.nombre,
        categoriaColor: _tipos[i].categoria.color,
        precio: _tipos[i].precio,
        rangos: rangosValidos
            .map((r) => RangoSnap(desde: r.desde!, hasta: r.hasta!))
            .toList(),
      ));
    }

    final control = ControlCaja(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fecha: _fecha,
      lineas: lineas,
    );

    final historial = await GestorStorage.cargarControlCaja();
    historial.insert(0, control);
    await GestorStorage.guardarControlCaja(historial);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Control guardado · ${formatPesos(_total)}')),
    );
    _limpiar();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) setState(() => _fecha = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _HistorialCajaScreen()),
            ),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _tipos.isEmpty
              ? _SinTipos()
              : Column(
                  children: [
                    // Selector de fecha
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: cs.surfaceContainerLow,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.azulMarino),
                            const SizedBox(width: 8),
                            Text(
                              _fmtFecha(_fecha),
                              style: theme.textTheme.titleSmall?.copyWith(color: AppColors.azulMarino),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.azulMarino),
                          ],
                        ),
                      ),
                    ),
                    // Cards por tipo
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _tipos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _TipoCard(
                          tipo: _tipos[i],
                          rangos: _rangos[i],
                          subtotal: _subtotalTipo(i),
                          onChanged: () => setState(() {}),
                          onAgregarRango: () => _agregarRango(i),
                          onEliminarRango: (j) => _eliminarRango(i, j),
                        ),
                      ),
                    ),
                    // Footer total
                    _TotalFooter(totalBoletos: _totalBoletos, total: _total),
                    // Botones
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _limpiar,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Limpiar'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _guardar,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Guardar control'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Card por tipo ────────────────────────────────────────────────────────────

class _TipoCard extends StatelessWidget {
  final TipoTalonario tipo;
  final List<_RangoEntry> rangos;
  final double subtotal;
  final VoidCallback onChanged;
  final VoidCallback onAgregarRango;
  final void Function(int) onEliminarRango;

  const _TipoCard({
    required this.tipo,
    required this.rangos,
    required this.subtotal,
    required this.onChanged,
    required this.onAgregarRango,
    required this.onEliminarRango,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = tipo.categoria.color;
    final tieneValor = subtotal > 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: tieneValor ? color.withAlpha(120) : cs.outlineVariant,
          width: tieneValor ? 1.5 : 1,
        ),
      ),
      color: tieneValor ? color.withAlpha(8) : cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 8),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tipo.boletos} boletos × ${formatPesos(tipo.precio)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        tipo.categoria.nombre,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subtotal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formatPesos(subtotal),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Encabezado de rangos
            Row(
              children: [
                Expanded(
                  child: Text('Desde',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Hasta',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text('Boletos',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 6),
            // Filas de rangos
            ...rangos.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RangoRow(
                    rango: e.value,
                    color: color,
                    canRemove: rangos.length > 1,
                    onChanged: onChanged,
                    onRemove: () => onEliminarRango(e.key),
                  ),
                )),
            // Botón agregar rango
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAgregarRango,
                icon: Icon(Icons.add, size: 16, color: color),
                label: Text('Agregar rango',
                    style: TextStyle(color: color, fontSize: 13)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fila de rango ────────────────────────────────────────────────────────────

class _RangoRow extends StatelessWidget {
  final _RangoEntry rango;
  final Color color;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _RangoRow({
    required this.rango,
    required this.color,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hayError = rango.hayError;
    final boletos = rango.boletos;
    final borderColor = hayError ? cs.error : (rango.esValido ? color : cs.outlineVariant);
    final borderWidth = (hayError || rango.esValido) ? 1.5 : 1.0;

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: borderWidth),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: hayError ? cs.error : color, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cs.error, width: 1.5),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: rango.desdeCtrl,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.bodyMedium,
            decoration: deco('Desde'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: rango.hastaCtrl,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.bodyMedium,
            decoration: deco('Hasta'),
          ),
        ),
        const SizedBox(width: 8),
        // Badge de boletos
        SizedBox(
          width: 72,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: hayError
                ? Icon(Icons.error_outline, size: 18, color: cs.error, key: const ValueKey('err'))
                : boletos > 0
                    ? Container(
                        key: ValueKey(boletos),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$boletos',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
        // Botón eliminar
        SizedBox(
          width: 36,
          child: canRemove
              ? IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      size: 18, color: cs.onSurfaceVariant),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Footer de totales ────────────────────────────────────────────────────────

class _TotalFooter extends StatelessWidget {
  final int totalBoletos;
  final double total;

  const _TotalFooter({required this.totalBoletos, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.azulMarino,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'TOTAL DEL DÍA',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            totalBoletos > 0 ? '$totalBoletos boletos' : '—',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            total > 0 ? formatPesos(total) : '—',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sin tipos ────────────────────────────────────────────────────────────────

class _SinTipos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text('Sin tipos de talonario',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Creá tipos en el Gestor de Talonarios',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

// ─── Historial de controles ───────────────────────────────────────────────────

class _HistorialCajaScreen extends StatefulWidget {
  const _HistorialCajaScreen();

  @override
  State<_HistorialCajaScreen> createState() => _HistorialCajaScreenState();
}

class _HistorialCajaScreenState extends State<_HistorialCajaScreen> {
  List<ControlCaja> _historial = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await GestorStorage.cargarControlCaja();
    if (!mounted) return;
    setState(() {
      _historial = data;
      _loaded = true;
    });
  }

  Future<void> _eliminar(ControlCaja c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Eliminar el control del ${_fmtFecha(c.fecha)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _historial.remove(c));
    GestorStorage.guardarControlCaja(_historial).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Caja')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 56,
                          color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      Text('Sin controles guardados',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _historial.length,
                  itemBuilder: (_, i) => _ControlCard(
                        control: _historial[i],
                        onEliminar: () => _eliminar(_historial[i]),
                      ),
                ),
    );
  }
}

// ─── Card de historial ────────────────────────────────────────────────────────

class _ControlCard extends StatelessWidget {
  final ControlCaja control;
  final VoidCallback onEliminar;

  const _ControlCard({required this.control, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const CircleAvatar(
            backgroundColor: AppColors.azulMarinoContainer,
            child: Icon(Icons.point_of_sale_outlined, color: AppColors.azulMarino, size: 20),
          ),
          title: Text(
            _fmtFechaHora(control.fecha),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${control.totalBoletos} boletos · ${formatPesos(control.total)}',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...control.lineas.map((linea) => _LineaDetalle(linea: linea)),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('TOTAL',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text(
                  '${control.totalBoletos} boletos',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  formatPesos(control.total),
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.hunterGreen),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onEliminar,
              icon: Icon(Icons.delete_outline, size: 16, color: cs.error),
              label: Text('Eliminar registro', style: TextStyle(color: cs.error)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaDetalle extends StatelessWidget {
  final ControlCajaLinea linea;
  const _LineaDetalle({required this.linea});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = linea.categoriaColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la línea
          Row(
            children: [
              CircleAvatar(backgroundColor: color, radius: 6),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${linea.descripcion} — ${linea.categoriaNombre}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatPesos(linea.subtotal),
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          // Rangos
          ...linea.rangos.map((r) => Padding(
                padding: const EdgeInsets.only(top: 4, left: 20),
                child: Row(
                  children: [
                    Icon(Icons.subdirectory_arrow_right,
                        size: 14, color: cs.outlineVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${r.desde} → ${r.hasta}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${r.boletos} bol',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: color, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatPesos(r.boletos * linea.precio),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
