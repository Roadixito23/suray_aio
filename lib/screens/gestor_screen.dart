import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria_talonario.dart';
import '../models/tipo_talonario.dart';
import '../services/gestor_storage.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

const _paletaColores = [
  Color(0xFFD32F2F), // Rojo
  Color(0xFF388E3C), // Verde
  Color(0xFF1976D2), // Azul
  AppColors.burdeo,
  AppColors.azulMarino,
  AppColors.hunterGreen,
  Color(0xFF7B4F00),
  Color(0xFF4E616D),
  Color(0xFFE65100),
  Color(0xFF6750A4),
  Color(0xFF006A6A),
];

// ─── Pantalla principal ───────────────────────────────────────────────────────

class GestorScreen extends StatefulWidget {
  const GestorScreen({super.key});

  @override
  State<GestorScreen> createState() => _GestorScreenState();
}

class _GestorScreenState extends State<GestorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<TipoTalonario> _tipos = [];
  final List<CategoriaTalonario> _categorias = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final categorias = await GestorStorage.cargarCategorias();
    final tipos = await GestorStorage.cargarTipos(categorias);
    if (!mounted) return;
    setState(() {
      _categorias
        ..clear()
        ..addAll(categorias);
      _tipos
        ..clear()
        ..addAll(tipos);
      _loaded = true;
    });
  }

  void _guardarTodo() {
    Future.wait([
      GestorStorage.guardarCategorias(_categorias),
      GestorStorage.guardarTipos(_tipos),
    ]).ignore();
  }

  // ── CRUD Categorías ──────────────────────────────────────────────────────────

  void _crearCategoria(CategoriaTalonario c) {
    setState(() => _categorias.add(c));
    _guardarTodo();
  }

  void _editarCategoria(CategoriaTalonario old, CategoriaTalonario nueva) {
    final idx = _categorias.indexWhere((c) => c.id == old.id);
    if (idx == -1) return;
    setState(() {
      _categorias[idx] = nueva;
      for (int i = 0; i < _tipos.length; i++) {
        if (_tipos[i].categoria.id == old.id) {
          _tipos[i] = TipoTalonario(
            id: _tipos[i].id,
            boletos: _tipos[i].boletos,
            precio: _tipos[i].precio,
            categoria: nueva,
            esPredefinido: _tipos[i].esPredefinido,
          );
        }
      }
    });
    _guardarTodo();
  }

  Future<void> _eliminarCategoria(CategoriaTalonario cat) async {
    final n = _tipos.where((t) => t.categoria.id == cat.id).length;
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se puede eliminar: $n tipo${n == 1 ? '' : 's'} la usan'),
      ));
      return;
    }
    final ok = await _confirmar('¿Eliminar la categoría "${cat.nombre}"?');
    if (ok != true || !mounted) return;
    setState(() => _categorias.removeWhere((c) => c.id == cat.id));
    _guardarTodo();
  }

  // ── CRUD Tipos ───────────────────────────────────────────────────────────────

  void _crearTipo(TipoTalonario t) {
    setState(() => _tipos.add(t));
    _guardarTodo();
  }

  void _editarTipo(TipoTalonario old, TipoTalonario nuevo) {
    final idx = _tipos.indexWhere((t) => t.id == old.id);
    if (idx == -1) return;
    setState(() => _tipos[idx] = nuevo);
    _guardarTodo();
  }

  Future<void> _eliminarTipo(TipoTalonario tipo) async {
    final ok = await _confirmar(
        '¿Eliminar el tipo "${tipo.boletos} boletos × ${formatPesos(tipo.precio)}"?');
    if (ok != true || !mounted) return;
    setState(() => _tipos.removeWhere((t) => t.id == tipo.id));
    _guardarTodo();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<bool?> _confirmar(String mensaje) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar'),
          content: Text(mensaje),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

  void _mostrarSheet(WidgetBuilder builder) {
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
        child: builder(ctx),
      ),
    );
  }

  void _onFabPressed() {
    switch (_tabController.index) {
      case 0:
        _mostrarSheet((_) => _CategoriaSheet(onGuardar: _crearCategoria));
      case 1:
        _mostrarSheet((_) => _TipoSheet(
              categorias: _categorias,
              onGuardar: _crearTipo,
            ));
    }
  }

  static const _fabLabels = ['Categoría', 'Tipo'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Talonarios'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.label_outline), text: 'Categorías'),
            Tab(icon: Icon(Icons.style_outlined), text: 'Tipos'),
          ],
        ),
      ),
      floatingActionButton: _loaded
          ? FloatingActionButton.extended(
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: Text(_fabLabels[_tabController.index]),
            )
          : null,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _CategoriasTab(
                  categorias: _categorias,
                  mostrarSheet: _mostrarSheet,
                  onEditar: _editarCategoria,
                  onEliminar: _eliminarCategoria,
                ),
                _TiposTab(
                  tipos: _tipos,
                  categorias: _categorias,
                  mostrarSheet: _mostrarSheet,
                  onEditar: _editarTipo,
                  onEliminar: _eliminarTipo,
                ),
              ],
            ),
    );
  }
}

// ─── Tab: Categorías ──────────────────────────────────────────────────────────

class _CategoriasTab extends StatelessWidget {
  final List<CategoriaTalonario> categorias;
  final void Function(WidgetBuilder) mostrarSheet;
  final void Function(CategoriaTalonario, CategoriaTalonario) onEditar;
  final Future<void> Function(CategoriaTalonario) onEliminar;

  const _CategoriasTab({
    required this.categorias,
    required this.mostrarSheet,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return const _EstadoVacio(
        icon: Icons.label_outline,
        mensaje: 'Sin categorías',
        subtitulo: 'Tocá + para crear una',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categorias.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final cat = categorias[i];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: cat.color, radius: 14),
            title: Text(cat.nombre),
            trailing: _AccionesMenu(
              onEditar: () => mostrarSheet((_) => _CategoriaSheet(
                    editando: cat,
                    onGuardar: (nueva) => onEditar(cat, nueva),
                  )),
              onEliminar: () => onEliminar(cat),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab: Tipos ───────────────────────────────────────────────────────────────

class _TiposTab extends StatelessWidget {
  final List<TipoTalonario> tipos;
  final List<CategoriaTalonario> categorias;
  final void Function(WidgetBuilder) mostrarSheet;
  final void Function(TipoTalonario, TipoTalonario) onEditar;
  final Future<void> Function(TipoTalonario) onEliminar;

  const _TiposTab({
    required this.tipos,
    required this.categorias,
    required this.mostrarSheet,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (tipos.isEmpty) {
      return const _EstadoVacio(
        icon: Icons.style_outlined,
        mensaje: 'Sin tipos',
        subtitulo: 'Tocá + para crear uno',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tipos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final tipo = tipos[i];
        final color = tipo.categoria.color;
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color, radius: 14),
            title: Text('${tipo.boletos} boletos × ${formatPesos(tipo.precio)}'),
            subtitle: Text(tipo.categoria.nombre),
            trailing: _AccionesMenu(
              onEditar: () => mostrarSheet((_) => _TipoSheet(
                    categorias: categorias,
                    editando: tipo,
                    onGuardar: (nuevo) => onEditar(tipo, nuevo),
                  )),
              onEliminar: () => onEliminar(tipo),
            ),
          ),
        );
      },
    );
  }
}

// ─── Menú de acciones (editar / eliminar) ────────────────────────────────────

class _AccionesMenu extends StatelessWidget {
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _AccionesMenu({required this.onEditar, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<_Accion>(
      icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
      onSelected: (a) {
        if (a == _Accion.editar) onEditar();
        if (a == _Accion.eliminar) onEliminar();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _Accion.editar,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: cs.onSurface),
              const SizedBox(width: 12),
              const Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _Accion.eliminar,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: cs.error),
              const SizedBox(width: 12),
              Text('Eliminar', style: TextStyle(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Accion { editar, eliminar }

// ─── Helpers visuales ────────────────────────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  final IconData icon;
  final String mensaje;
  final String subtitulo;
  const _EstadoVacio(
      {required this.icon, required this.mensaje, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(mensaje,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(subtitulo,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

// ─── Sheet compartidos ────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

// ─── Sheet: Categoría (crear / editar) ───────────────────────────────────────

class _CategoriaSheet extends StatefulWidget {
  final CategoriaTalonario? editando;
  final void Function(CategoriaTalonario) onGuardar;

  const _CategoriaSheet({required this.onGuardar, this.editando});

  @override
  State<_CategoriaSheet> createState() => _CategoriaSheetState();
}

class _CategoriaSheetState extends State<_CategoriaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  late Color _colorSel;

  bool get _esEdicion => widget.editando != null;

  @override
  void initState() {
    super.initState();
    _colorSel = widget.editando?.color ?? _paletaColores.first;
    if (_esEdicion) _nombreCtrl.text = widget.editando!.nombre;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final categoria = CategoriaTalonario(
      id: widget.editando?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreCtrl.text.trim(),
      color: _colorSel,
      esPredefinida: widget.editando?.esPredefinida ?? false,
    );
    Navigator.pop(context);
    widget.onGuardar(categoria);
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
          const _SheetHandle(),
          Text(_esEdicion ? 'Editar categoría' : 'Nueva categoría',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría',
              prefixIcon: Icon(Icons.label_outline),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 16),
          Text('Color',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: _paletaColores
                .map((c) => GestureDetector(
                      onTap: () => setState(() => _colorSel = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: _colorSel == c
                              ? Border.all(
                                  color: theme.colorScheme.onSurface, width: 3)
                              : null,
                        ),
                        child: _colorSel == c
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: Icon(_esEdicion ? Icons.save_outlined : Icons.add),
            label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar'),
            style:
                FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Tipo (crear / editar) ────────────────────────────────────────────

class _TipoSheet extends StatefulWidget {
  final List<CategoriaTalonario> categorias;
  final TipoTalonario? editando;
  final void Function(TipoTalonario) onGuardar;

  const _TipoSheet({
    required this.categorias,
    required this.onGuardar,
    this.editando,
  });

  @override
  State<_TipoSheet> createState() => _TipoSheetState();
}

class _TipoSheetState extends State<_TipoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _boletosCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  late CategoriaTalonario _categoriaSel;

  bool get _esEdicion => widget.editando != null;

  @override
  void initState() {
    super.initState();
    _categoriaSel = widget.editando?.categoria ?? widget.categorias.first;
    if (_esEdicion) {
      _boletosCtrl.text = widget.editando!.boletos.toString();
      final p = widget.editando!.precio;
      _precioCtrl.text =
          p == p.roundToDouble() ? p.toInt().toString() : p.toString();
    }
  }

  @override
  void dispose() {
    _boletosCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final tipo = TipoTalonario(
      id: widget.editando?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      boletos: int.parse(_boletosCtrl.text),
      precio: double.parse(_precioCtrl.text.replaceAll(',', '.')),
      categoria: _categoriaSel,
      esPredefinido: widget.editando?.esPredefinido ?? false,
    );
    Navigator.pop(context);
    widget.onGuardar(tipo);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          Text(
              _esEdicion
                  ? 'Editar tipo de talonario'
                  : 'Nuevo tipo de talonario',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _boletosCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Boletos',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obligatorio';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _precioCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obligatorio';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Inválido';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CategoriaTalonario>(
            initialValue: _categoriaSel,
            decoration: const InputDecoration(
              labelText: 'Categoría / Color',
              prefixIcon: Icon(Icons.label_outline),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: widget.categorias
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: c.color, radius: 8),
                          const SizedBox(width: 8),
                          Text(c.nombre),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _categoriaSel = v!),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: Icon(_esEdicion ? Icons.save_outlined : Icons.add),
            label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar'),
            style:
                FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}
