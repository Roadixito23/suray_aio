import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/item_inventario.dart';
import '../models/sobre_historial.dart';
import '../services/gestor_storage.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'historial_screen.dart';

// ─── Private models ───────────────────────────────────────────────────────────

enum _Turno { manana, tarde }

class _Voucher {
  final String id;
  final DateTime fecha;
  final double total;
  final _Turno turno;
  _Voucher({required this.id, required this.fecha, required this.total, required this.turno});
}

class _Combustible {
  final String id;
  final DateTime fecha;
  final double total;
  final String chofer;
  final String numeroMaquina;
  final String patente;
  _Combustible({
    required this.id,
    required this.fecha,
    required this.total,
    required this.chofer,
    required this.numeroMaquina,
    required this.patente,
  });
}

class _Otro {
  final String id;
  final DateTime fecha;
  final double total;
  final String descripcion;
  _Otro({required this.id, required this.fecha, required this.total, required this.descripcion});
}

String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

String _formatPatente(String raw) {
  if (RegExp(r'^[A-Z]{2}\d{4}$').hasMatch(raw)) return '${raw.substring(0, 2)}-${raw.substring(2)}';
  if (RegExp(r'^[A-Z]{4}\d{2}$').hasMatch(raw)) return '${raw.substring(0, 4)}-${raw.substring(4)}';
  return raw;
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class RendicionScreen extends StatefulWidget {
  const RendicionScreen({super.key});

  @override
  State<RendicionScreen> createState() => _RendicionScreenState();
}

class _RendicionScreenState extends State<RendicionScreen> {
  List<ItemInventario> _porRendir = [];
  final Set<String> _seleccionados = {};
  final List<_Voucher> _vouchers = [];
  final List<_Combustible> _combustibles = [];
  final List<_Otro> _otros = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final categorias = await GestorStorage.cargarCategorias();
    final tipos = await GestorStorage.cargarTipos(categorias);
    final todos = await GestorStorage.cargarInventario(tipos);
    if (!mounted) return;
    setState(() {
      _porRendir = todos.where((i) => i.estado == EstadoInventario.porRendir).toList();
      _seleccionados
        ..clear()
        ..addAll(_porRendir.map((i) => i.id));
      _loaded = true;
    });
  }

  double get _totalTalonarios => _porRendir
      .where((i) => _seleccionados.contains(i.id))
      .fold(0.0, (s, i) => s + i.tipo.boletos * i.tipo.precio);

  double get _totalVouchers => _vouchers.fold(0.0, (s, v) => s + v.total);
  double get _totalCombustible => _combustibles.fold(0.0, (s, c) => s + c.total);
  double get _totalOtros => _otros.fold(0.0, (s, o) => s + o.total);
  double get _efectivo => _totalTalonarios - _totalVouchers - _totalCombustible - _totalOtros;

  void _toggle(String id) => setState(() {
        if (_seleccionados.contains(id)) {
          _seleccionados.remove(id);
        } else {
          _seleccionados.add(id);
        }
      });

  void _sheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: child,
      ),
    );
  }

  Future<void> _cerrarSobre() async {
    if (_seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná al menos un talonario')),
      );
      return;
    }
    final n = _seleccionados.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sobre'),
        content: Text(
          'Se rendirán $n talonario${n == 1 ? '' : 's'}.\n'
          'Efectivo a ingresar: ${formatPesos(_efectivo)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Snapshot del sobre antes de borrar del inventario
    final selectedItems = _porRendir.where((i) => _seleccionados.contains(i.id)).toList();
    final sobre = SobreHistorial(
      id: _newId(),
      fechaCierre: DateTime.now(),
      talonarios: selectedItems
          .map((i) => SobreTalSnap(numero: i.numero, boletos: i.tipo.boletos, precio: i.tipo.precio))
          .toList(),
      vouchers: _vouchers
          .map((v) => SobreVoucherSnap(
                fecha: v.fecha,
                total: v.total,
                turno: v.turno == _Turno.manana ? 'Mañana' : 'Tarde',
              ))
          .toList(),
      combustibles: _combustibles
          .map((c) => SobreCombSnap(
                fecha: c.fecha,
                total: c.total,
                chofer: c.chofer,
                numeroMaquina: c.numeroMaquina,
                patente: c.patente,
              ))
          .toList(),
      otros: _otros
          .map((o) => SobreOtroSnap(fecha: o.fecha, total: o.total, descripcion: o.descripcion))
          .toList(),
      totalTalonarios: _totalTalonarios,
      totalVouchers: _totalVouchers,
      totalCombustible: _totalCombustible,
      totalOtros: _totalOtros,
      efectivo: _efectivo,
      estado: EstadoSobre.noEnviado,
    );

    final historial = await GestorStorage.cargarHistorial();
    historial.insert(0, sobre);
    await GestorStorage.guardarHistorial(historial);

    final categorias = await GestorStorage.cargarCategorias();
    final tipos = await GestorStorage.cargarTipos(categorias);
    final todos = await GestorStorage.cargarInventario(tipos);
    todos.removeWhere((i) => _seleccionados.contains(i.id));
    await GestorStorage.guardarInventario(todos);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sobre cerrado · ${formatPesos(_efectivo)} en efectivo')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendición'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de sobres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistorialScreen()),
            ),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _SectionHeader(
                        icon: Icons.assignment_outlined,
                        iconColor: AppColors.burdeo,
                        title: 'Talonarios a rendir',
                      ),
                      const SizedBox(height: 8),
                      if (_porRendir.isEmpty)
                        const _EmptyLabel('Sin talonarios por rendir')
                      else
                        ..._porRendir.map((item) => _TalonarioCheckTile(
                              item: item,
                              seleccionado: _seleccionados.contains(item.id),
                              onToggle: () => _toggle(item.id),
                            )),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.receipt_outlined,
                        iconColor: theme.colorScheme.primary,
                        title: 'Vouchers',
                        onAgregar: () => _sheet(_VoucherSheet(
                          onGuardar: (v) => setState(() => _vouchers.add(v)),
                        )),
                      ),
                      const SizedBox(height: 8),
                      if (_vouchers.isEmpty)
                        const _EmptyLabel('Sin vouchers')
                      else
                        ..._vouchers.map((v) => _SwipeToDelete(
                              id: 'v_${v.id}',
                              onDelete: () => setState(() => _vouchers.remove(v)),
                              child: _VoucherTile(v),
                            )),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.local_gas_station_outlined,
                        iconColor: theme.colorScheme.primary,
                        title: 'Combustible',
                        onAgregar: () => _sheet(_CombustibleSheet(
                          onGuardar: (c) => setState(() => _combustibles.add(c)),
                        )),
                      ),
                      const SizedBox(height: 8),
                      if (_combustibles.isEmpty)
                        const _EmptyLabel('Sin facturas de combustible')
                      else
                        ..._combustibles.map((c) => _SwipeToDelete(
                              id: 'c_${c.id}',
                              onDelete: () => setState(() => _combustibles.remove(c)),
                              child: _CombustibleTile(c),
                            )),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.more_horiz,
                        iconColor: theme.colorScheme.primary,
                        title: 'Otros',
                        onAgregar: () => _sheet(_OtroSheet(
                          onGuardar: (o) => setState(() => _otros.add(o)),
                        )),
                      ),
                      const SizedBox(height: 8),
                      if (_otros.isEmpty)
                        const _EmptyLabel('Sin otros consumos')
                      else
                        ..._otros.map((o) => _SwipeToDelete(
                              id: 'o_${o.id}',
                              onDelete: () => setState(() => _otros.remove(o)),
                              child: _OtroTile(o),
                            )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _ResumenSobre(
                  totalTalonarios: _totalTalonarios,
                  totalVouchers: _totalVouchers,
                  totalCombustible: _totalCombustible,
                  totalOtros: _totalOtros,
                  efectivo: _efectivo,
                  canCerrar: _seleccionados.isNotEmpty,
                  onCerrar: _cerrarSobre,
                ),
              ],
            ),
    );
  }
}

// ─── Section chrome ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onAgregar;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onAgregar != null)
          TextButton.icon(
            onPressed: onAgregar,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }
}

class _EmptyLabel extends StatelessWidget {
  final String text;
  const _EmptyLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
}

// ─── Talonario check tile ─────────────────────────────────────────────────────

class _TalonarioCheckTile extends StatelessWidget {
  final ItemInventario item;
  final bool seleccionado;
  final VoidCallback onToggle;

  const _TalonarioCheckTile({
    required this.item,
    required this.seleccionado,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = item.tipo.boletos * item.tipo.precio;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: seleccionado
            ? AppColors.burdeoContainer
            : theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: seleccionado
              ? const BorderSide(color: AppColors.burdeo, width: 1)
              : BorderSide.none,
        ),
        child: CheckboxListTile(
          value: seleccionado,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.burdeo,
          checkColor: Colors.white,
          title: Text('Talonario N° ${item.numero}', style: theme.textTheme.titleSmall),
          subtitle: Text(
            '${item.tipo.boletos} boletos × ${formatPesos(item.tipo.precio)} = ${formatPesos(total)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          controlAffinity: ListTileControlAffinity.trailing,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Swipe-to-delete wrapper ──────────────────────────────────────────────────

class _SwipeToDelete extends StatelessWidget {
  final String id;
  final VoidCallback onDelete;
  final Widget child;

  const _SwipeToDelete({required this.id, required this.onDelete, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
        ),
        child: child,
      ),
    );
  }
}

// ─── Item tiles ───────────────────────────────────────────────────────────────

class _VoucherTile extends StatelessWidget {
  final _Voucher v;
  const _VoucherTile(this.v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final turnoLabel = v.turno == _Turno.manana ? 'Turno Mañana' : 'Turno Tarde';
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.receipt_outlined, color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(formatPesos(v.total), style: theme.textTheme.titleSmall),
        subtitle: Text('$turnoLabel · ${_fmtFecha(v.fecha)}',
            style: theme.textTheme.bodySmall),
        trailing: Icon(Icons.swipe_left_outlined, size: 14,
            color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}

class _CombustibleTile extends StatelessWidget {
  final _Combustible c;
  const _CombustibleTile(this.c);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.local_gas_station_outlined,
              color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(formatPesos(c.total), style: theme.textTheme.titleSmall),
        subtitle: Text(
          '${c.chofer} · Máq ${c.numeroMaquina} · ${_formatPatente(c.patente)} · ${_fmtFecha(c.fecha)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(Icons.swipe_left_outlined, size: 14,
            color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}

class _OtroTile extends StatelessWidget {
  final _Otro o;
  const _OtroTile(this.o);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.more_horiz, color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(formatPesos(o.total), style: theme.textTheme.titleSmall),
        subtitle: Text('${o.descripcion} · ${_fmtFecha(o.fecha)}',
            style: theme.textTheme.bodySmall),
        trailing: Icon(Icons.swipe_left_outlined, size: 14,
            color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}

// ─── Bottom summary ───────────────────────────────────────────────────────────

class _ResumenSobre extends StatelessWidget {
  final double totalTalonarios;
  final double totalVouchers;
  final double totalCombustible;
  final double totalOtros;
  final double efectivo;
  final bool canCerrar;
  final VoidCallback onCerrar;

  const _ResumenSobre({
    required this.totalTalonarios,
    required this.totalVouchers,
    required this.totalCombustible,
    required this.totalOtros,
    required this.efectivo,
    required this.canCerrar,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row('Subtotal talonarios', formatPesos(totalTalonarios), theme),
          if (totalVouchers > 0)
            _Row('− Vouchers', '−${formatPesos(totalVouchers)}', theme, valueColor: cs.error),
          if (totalCombustible > 0)
            _Row('− Combustible', '−${formatPesos(totalCombustible)}', theme, valueColor: cs.error),
          if (totalOtros > 0)
            _Row('− Otros', '−${formatPesos(totalOtros)}', theme, valueColor: cs.error),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Efectivo a ingresar',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                formatPesos(efectivo),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: efectivo >= 0 ? AppColors.hunterGreen : cs.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: canCerrar ? onCerrar : null,
            icon: const Icon(Icons.mail_outlined),
            label: const Text('Cerrar sobre'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.burdeo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.burdeo.withAlpha(60),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _Row(this.label, this.value, this.theme, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: valueColor)),
          ],
        ),
      );
}

// ─── Sheet helpers ────────────────────────────────────────────────────────────

Widget _handle(ThemeData theme) => Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

class _DateTile extends StatelessWidget {
  final DateTime fecha;
  final ValueChanged<DateTime> onPicked;

  const _DateTile({required this.fecha, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined),
      title: const Text('Fecha'),
      subtitle: Text(_fmtFecha(fecha)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: theme.colorScheme.surfaceContainerLow,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null && context.mounted) onPicked(picked);
      },
    );
  }
}

class _TurnoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TurnoButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Voucher sheet ────────────────────────────────────────────────────────────

class _VoucherSheet extends StatefulWidget {
  final void Function(_Voucher) onGuardar;
  const _VoucherSheet({required this.onGuardar});

  @override
  State<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends State<_VoucherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _totalCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  _Turno _turno = _Turno.manana;

  @override
  void dispose() {
    _totalCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final v = _Voucher(
      id: _newId(),
      fecha: _fecha,
      total: double.parse(_totalCtrl.text.trim()),
      turno: _turno,
    );
    Navigator.pop(context);
    widget.onGuardar(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(theme),
          Text('Agregar voucher', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _DateTile(fecha: _fecha, onPicked: (d) => setState(() => _fecha = d)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TurnoButton(
                  label: 'Turno Mañana',
                  icon: Icons.wb_sunny_outlined,
                  selected: _turno == _Turno.manana,
                  onTap: () => setState(() => _turno = _Turno.manana),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TurnoButton(
                  label: 'Turno Tarde',
                  icon: Icons.nights_stay_outlined,
                  selected: _turno == _Turno.tarde,
                  onTap: () => setState(() => _turno = _Turno.tarde),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Total (\$)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
              if (double.tryParse(v) == null) return 'Valor inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.add),
            label: const Text('Agregar voucher'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── Combustible sheet ────────────────────────────────────────────────────────

class _CombustibleSheet extends StatefulWidget {
  final void Function(_Combustible) onGuardar;
  const _CombustibleSheet({required this.onGuardar});

  @override
  State<_CombustibleSheet> createState() => _CombustibleSheetState();
}

class _CombustibleSheetState extends State<_CombustibleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _totalCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();
  final _maquinaCtrl = TextEditingController();
  final _patenteCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _totalCtrl.dispose();
    _choferCtrl.dispose();
    _maquinaCtrl.dispose();
    _patenteCtrl.dispose();
    super.dispose();
  }

  String? _validarPatente(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final u = v.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}\d{4}$').hasMatch(u) && !RegExp(r'^[A-Z]{4}\d{2}$').hasMatch(u)) {
      return 'Formato inválido (ej: AB1234 o ABCD12)';
    }
    return null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final c = _Combustible(
      id: _newId(),
      fecha: _fecha,
      total: double.parse(_totalCtrl.text.trim()),
      chofer: _choferCtrl.text.trim(),
      numeroMaquina: _maquinaCtrl.text.trim(),
      patente: _patenteCtrl.text.trim().toUpperCase(),
    );
    Navigator.pop(context);
    widget.onGuardar(c);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(theme),
          Text('Factura de combustible', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _DateTile(fecha: _fecha, onPicked: (d) => setState(() => _fecha = d)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _choferCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Chofer',
              prefixIcon: Icon(Icons.person_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _maquinaCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'N° Máquina',
                    prefixIcon: Icon(Icons.directions_bus_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _patenteCtrl,
                  inputFormatters: [
                    _UpperCaseFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Patente',
                    prefixIcon: Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'AB1234',
                  ),
                  validator: _validarPatente,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Total (\$)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
              if (double.tryParse(v) == null) return 'Valor inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.add),
            label: const Text('Agregar factura'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── Otro sheet ───────────────────────────────────────────────────────────────

class _OtroSheet extends StatefulWidget {
  final void Function(_Otro) onGuardar;
  const _OtroSheet({required this.onGuardar});

  @override
  State<_OtroSheet> createState() => _OtroSheetState();
}

class _OtroSheetState extends State<_OtroSheet> {
  final _formKey = GlobalKey<FormState>();
  final _totalCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _totalCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final o = _Otro(
      id: _newId(),
      fecha: _fecha,
      total: double.parse(_totalCtrl.text.trim()),
      descripcion: _descripcionCtrl.text.trim(),
    );
    Navigator.pop(context);
    widget.onGuardar(o);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(theme),
          Text('Otro consumo', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _DateTile(fecha: _fecha, onPicked: (d) => setState(() => _fecha = d)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descripcionCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              prefixIcon: Icon(Icons.edit_note_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Total (\$)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
              if (double.tryParse(v) == null) return 'Valor inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.add),
            label: const Text('Agregar consumo'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}
