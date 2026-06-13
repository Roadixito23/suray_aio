import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/item_inventario.dart';
import '../models/tipo_talonario.dart';
import '../services/gestor_storage.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final List<TipoTalonario> _tipos = [];
  final List<ItemInventario> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final categorias = await GestorStorage.cargarCategorias();
    final tipos = await GestorStorage.cargarTipos(categorias);
    final items = await GestorStorage.cargarInventario(tipos);
    if (!mounted) return;
    setState(() {
      _tipos
        ..clear()
        ..addAll(tipos);
      _items
        ..clear()
        ..addAll(items);
      _loaded = true;
    });
  }

  void _guardar() => GestorStorage.guardarInventario(_items).ignore();

  // ── CRUD ────────────────────────────────────────────────────────────────────

  void _agregar(ItemInventario item) {
    setState(() => _items.add(item));
    _guardar();
  }

  void _editar(ItemInventario original, ItemInventario actualizado) {
    final idx = _items.indexWhere((i) => i.id == original.id);
    if (idx == -1) return;
    setState(() => _items[idx] = actualizado);
    _guardar();
  }

  Future<void> _eliminar(ItemInventario item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar talonario'),
        content: Text('¿Eliminar el talonario N° ${item.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _items.removeWhere((i) => i.id == item.id));
    _guardar();
  }

  void _marcarPorRendir(ItemInventario item) {
    final idx = _items.indexOf(item);
    if (idx == -1) return;
    setState(
        () => _items[idx] = item.copyWith(estado: EstadoInventario.porRendir));
    _guardar();
  }

  // ── Sheets ──────────────────────────────────────────────────────────────────

  void _mostrarSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 8, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: child,
      ),
    );
  }

  void _mostrarAgregar() {
    if (_tipos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Primero creá al menos un tipo en el Gestor de Talonarios'),
        ),
      );
      return;
    }
    _mostrarSheet(_ItemSheet(tipos: _tipos, onGuardar: _agregar));
  }

  void _mostrarEditar(ItemInventario item) {
    _mostrarSheet(_ItemSheet(
      tipos: _tipos,
      editando: item,
      onGuardar: (actualizado) => _editar(item, actualizado),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  Map<String, List<ItemInventario>> get _agrupados {
    final map = <String, List<ItemInventario>>{};
    for (final item in _items) {
      (map[item.tipo.id] ??= []).add(item);
    }
    return map;
  }

  List<Widget> _buildListItems(BuildContext context) {
    final grouped = _agrupados;
    final widgets = <Widget>[];
    for (final tipoId in grouped.keys) {
      final groupItems = grouped[tipoId]!;
      final tipo = groupItems.first.tipo;
      widgets.add(_TipoSectionHeader(tipo: tipo, count: groupItems.length));
      for (final item in groupItems) {
        widgets.add(
          _InventarioItemTile(
            key: Key(item.id),
            item: item,
            onEditar: () => _mostrarEditar(item),
            onEliminar: () => _eliminar(item),
            onPorRendir: () => _marcarPorRendir(item),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de Talonarios')),
      floatingActionButton: _loaded
          ? FloatingActionButton.extended(
              onPressed: _mostrarAgregar,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            )
          : null,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const _EstadoVacio()
              : Column(
                  children: [
                    _ResumenCard(items: _items),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        children: _buildListItems(context),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Resumen ──────────────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final List<ItemInventario> items;
  const _ResumenCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final countById = <String, int>{};
    final tipoById = <String, TipoTalonario>{};
    for (final item in items) {
      countById[item.tipo.id] = (countById[item.tipo.id] ?? 0) + 1;
      tipoById[item.tipo.id] = item.tipo;
    }

    final totalBoletos = items.fold<int>(0, (s, i) => s + i.tipo.boletos);
    final porRendirCount =
        items.where((i) => i.estado == EstadoInventario.porRendir).length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hunterGreenContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 18, color: AppColors.hunterGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${items.length} talonario${items.length == 1 ? '' : 's'} · $totalBoletos boletos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.onHunterGreenContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (porRendirCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.burdeoContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$porRendirCount por rendir',
                    style: const TextStyle(
                      color: AppColors.burdeo,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: countById.entries.map((e) {
              final tipo = tipoById[e.key]!;
              return _TipoConteoChip(tipo: tipo, cantidad: e.value);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TipoConteoChip extends StatelessWidget {
  final TipoTalonario tipo;
  final int cantidad;
  const _TipoConteoChip({required this.tipo, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final color = tipo.categoria.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color.fromARGB(
          40,
          (color.r * 255).round(),
          (color.g * 255).round(),
          (color.b * 255).round(),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${tipo.boletos}×${formatPesos(tipo.precio)} = ${formatPesos(tipo.boletos * tipo.precio * cantidad)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Lista agrupada ───────────────────────────────────────────────────────────

class _TipoSectionHeader extends StatelessWidget {
  final TipoTalonario tipo;
  final int count;
  const _TipoSectionHeader({required this.tipo, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tipo.categoria.color;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${tipo.boletos} boletos × ${formatPesos(tipo.precio)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color.fromARGB(
                30,
                (color.r * 255).round(),
                (color.g * 255).round(),
                (color.b * 255).round(),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventarioItemTile extends StatelessWidget {
  final ItemInventario item;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onPorRendir;

  const _InventarioItemTile({
    super.key,
    required this.item,
    required this.onEditar,
    required this.onEliminar,
    required this.onPorRendir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPorRendir = item.estado == EstadoInventario.porRendir;
    final accentColor =
        isPorRendir ? AppColors.burdeo : item.tipo.categoria.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key('dismissible_${item.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          if (isPorRendir) return true;
          onPorRendir();
          return false;
        },
        onDismissed: isPorRendir ? (_) => onEliminar() : null,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: isPorRendir
                ? theme.colorScheme.errorContainer
                : AppColors.burdeoContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPorRendir ? Icons.delete_outline : Icons.assignment_outlined,
            color: isPorRendir
                ? theme.colorScheme.onErrorContainer
                : AppColors.burdeo,
          ),
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: isPorRendir
              ? AppColors.burdeoContainer
              : theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPorRendir
                ? const BorderSide(color: AppColors.burdeo, width: 1)
                : BorderSide.none,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPorRendir
                  ? AppColors.burdeo.withAlpha(40)
                  : Color.fromARGB(
                      38,
                      (item.tipo.categoria.color.r * 255).round(),
                      (item.tipo.categoria.color.g * 255).round(),
                      (item.tipo.categoria.color.b * 255).round(),
                    ),
              child: Icon(
                isPorRendir ? Icons.assignment_outlined : Icons.book_outlined,
                color: accentColor,
                size: 20,
              ),
            ),
            title: Text(
              'N° ${item.numero}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isPorRendir ? AppColors.onBurdeoContainer : null,
              ),
            ),
            subtitle: Text(
              isPorRendir ? 'Por rendir' : item.tipo.categoria.nombre,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isPorRendir
                    ? AppColors.burdeo
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isPorRendir ? FontWeight.w600 : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.azulMarino.withAlpha(180)),
                  onPressed: onEditar,
                  tooltip: 'Editar',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: theme.colorScheme.error.withAlpha(180)),
                  onPressed: onEliminar,
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'Inventario vacío',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Tocá + para agregar talonarios',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Agregar / Editar ítem ────────────────────────────────────────────

class _ItemSheet extends StatefulWidget {
  final List<TipoTalonario> tipos;
  final ItemInventario? editando;
  final void Function(ItemInventario) onGuardar;

  const _ItemSheet({
    required this.tipos,
    required this.onGuardar,
    this.editando,
  });

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  late TipoTalonario _tipoSel;

  bool get _esEdicion => widget.editando != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _tipoSel = widget.editando!.tipo;
      _numeroCtrl.text = widget.editando!.numero;
    } else {
      _tipoSel = widget.tipos.first;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final item = ItemInventario(
      id: widget.editando?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: _tipoSel,
      numero: _numeroCtrl.text.trim(),
      estado: widget.editando?.estado ?? EstadoInventario.enStock,
    );
    Navigator.pop(context);
    widget.onGuardar(item);
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            _esEdicion ? 'Editar talonario' : 'Agregar talonario',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TipoTalonario>(
            initialValue: _tipoSel,
            decoration: const InputDecoration(
              labelText: 'Tipo de talonario',
              prefixIcon: Icon(Icons.style_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: widget.tipos
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        CircleAvatar(
                            backgroundColor: t.categoria.color, radius: 8),
                        const SizedBox(width: 8),
                        Text(
                            '${t.boletos} boletos × ${formatPesos(t.precio)}'),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _tipoSel = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _numeroCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Número de talonario',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: Icon(_esEdicion ? Icons.save_outlined : Icons.add),
            label: Text(_esEdicion ? 'Guardar cambios' : 'Agregar al inventario'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
