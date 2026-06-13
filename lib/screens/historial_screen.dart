import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sobre_historial.dart';
import '../services/gestor_storage.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

// ─── Helpers de estado ────────────────────────────────────────────────────────

String _estadoLabel(EstadoSobre e) => switch (e) {
      EstadoSobre.noEnviado => 'No enviado',
      EstadoSobre.enviado => 'Enviado',
      EstadoSobre.timbrado => 'Timbrado',
    };

Color _estadoColor(EstadoSobre e) => switch (e) {
      EstadoSobre.noEnviado => const Color(0xFF8A8A8A),
      EstadoSobre.enviado => AppColors.azulMarino,
      EstadoSobre.timbrado => AppColors.hunterGreen,
    };

IconData _estadoIcon(EstadoSobre e) => switch (e) {
      EstadoSobre.noEnviado => Icons.mail_outline,
      EstadoSobre.enviado => Icons.send_outlined,
      EstadoSobre.timbrado => Icons.verified_outlined,
    };

EstadoSobre? _siguiente(EstadoSobre e) => switch (e) {
      EstadoSobre.noEnviado => EstadoSobre.enviado,
      EstadoSobre.enviado => EstadoSobre.timbrado,
      EstadoSobre.timbrado => null,
    };

String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String _fmtFechaHora(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

String _formatPatente(String raw) {
  if (RegExp(r'^[A-Z]{2}\d{4}$').hasMatch(raw)) return '${raw.substring(0, 2)}-${raw.substring(2)}';
  if (RegExp(r'^[A-Z]{4}\d{2}$').hasMatch(raw)) return '${raw.substring(0, 4)}-${raw.substring(4)}';
  return raw;
}

// ─── Pantalla ─────────────────────────────────────────────────────────────────

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<SobreHistorial> _historial = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await GestorStorage.cargarHistorial();
    if (!mounted) return;
    setState(() {
      _historial = data;
      _loaded = true;
    });
  }

  void _guardar() => GestorStorage.guardarHistorial(_historial).ignore();

  void _avanzarEstado(int idx) {
    final siguiente = _siguiente(_historial[idx].estado);
    if (siguiente == null) return;
    setState(() => _historial[idx] = _historial[idx].copyWith(estado: siguiente));
    _guardar();
  }

  void _eliminar(SobreHistorial sobre) {
    setState(() => _historial.remove(sobre));
    _guardar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Sobres')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
              ? _EstadoVacio()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _historial.length,
                  itemBuilder: (_, i) => _SobreCard(
                    sobre: _historial[i],
                    onAvanzar: () => _avanzarEstado(i),
                    onEliminar: () => _eliminar(_historial[i]),
                  ),
                ),
    );
  }
}

// ─── Card de sobre ────────────────────────────────────────────────────────────

class _SobreCard extends StatelessWidget {
  final SobreHistorial sobre;
  final VoidCallback onAvanzar;
  final VoidCallback onEliminar;

  const _SobreCard({
    required this.sobre,
    required this.onAvanzar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _estadoColor(sobre.estado);
    final isFinal = _siguiente(sobre.estado) == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withAlpha(80), width: 1),
        ),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(_estadoIcon(sobre.estado), color: color, size: 20),
          ),
          title: Text(
            _fmtFechaHora(sobre.fechaCierre),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${sobre.talonarios.length} talonario${sobre.talonarios.length == 1 ? '' : 's'} · ${formatPesos(sobre.efectivo)} en efectivo',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EstadoChip(sobre: sobre, onAvanzar: isFinal ? null : onAvanzar),
              const SizedBox(width: 4),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Talonarios
            if (sobre.talonarios.isNotEmpty) ...[
              _SubHeader('Talonarios', Icons.assignment_outlined, AppColors.burdeo),
              const SizedBox(height: 6),
              ...sobre.talonarios.map((t) => _ItemRow(
                    label: 'N° ${t.numero}',
                    value: '${t.boletos} bol × ${formatPesos(t.precio)} = ${formatPesos(t.total)}',
                  )),
              const SizedBox(height: 10),
            ],
            // Vouchers
            if (sobre.vouchers.isNotEmpty) ...[
              _SubHeader('Vouchers', Icons.receipt_outlined, cs.primary),
              const SizedBox(height: 6),
              ...sobre.vouchers.map((v) => _ItemRow(
                    label: 'Turno ${v.turno} · ${_fmtFecha(v.fecha)}',
                    value: formatPesos(v.total),
                  )),
              const SizedBox(height: 10),
            ],
            // Combustible
            if (sobre.combustibles.isNotEmpty) ...[
              _SubHeader('Combustible', Icons.local_gas_station_outlined, cs.primary),
              const SizedBox(height: 6),
              ...sobre.combustibles.map((c) => _ItemRow(
                    label: '${c.chofer} · Máq ${c.numeroMaquina} · ${_formatPatente(c.patente)} · ${_fmtFecha(c.fecha)}',
                    value: formatPesos(c.total),
                  )),
              const SizedBox(height: 10),
            ],
            // Otros
            if (sobre.otros.isNotEmpty) ...[
              _SubHeader('Otros', Icons.more_horiz, cs.primary),
              const SizedBox(height: 6),
              ...sobre.otros.map((o) => _ItemRow(
                    label: '${o.descripcion} · ${_fmtFecha(o.fecha)}',
                    value: formatPesos(o.total),
                  )),
              const SizedBox(height: 10),
            ],
            // Resumen financiero
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ResRow('Subtotal talonarios', formatPesos(sobre.totalTalonarios), theme),
                  if (sobre.totalVouchers > 0)
                    _ResRow('− Vouchers', '−${formatPesos(sobre.totalVouchers)}', theme,
                        valueColor: cs.error),
                  if (sobre.totalCombustible > 0)
                    _ResRow('− Combustible', '−${formatPesos(sobre.totalCombustible)}', theme,
                        valueColor: cs.error),
                  if (sobre.totalOtros > 0)
                    _ResRow('− Otros', '−${formatPesos(sobre.totalOtros)}', theme,
                        valueColor: cs.error),
                  const Divider(height: 12),
                  _ResRow(
                    'Efectivo a ingresar',
                    formatPesos(sobre.efectivo),
                    theme,
                    bold: true,
                    valueColor: sobre.efectivo >= 0 ? AppColors.hunterGreen : cs.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Botón eliminar
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar sobre'),
                    content: const Text('¿Eliminar este registro del historial?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (ok == true) onEliminar();
              },
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

// ─── Estado chip ──────────────────────────────────────────────────────────────

class _EstadoChip extends StatelessWidget {
  final SobreHistorial sobre;
  final VoidCallback? onAvanzar;

  const _EstadoChip({required this.sobre, required this.onAvanzar});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(sobre.estado);
    final label = _estadoLabel(sobre.estado);
    final icon = _estadoIcon(sobre.estado);
    final isFinal = onAvanzar == null;

    if (isFinal) {
      return Chip(
        avatar: Icon(icon, size: 14, color: color),
        label: Text(label),
        labelStyle: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        backgroundColor: color.withAlpha(25),
        side: BorderSide(color: color.withAlpha(80)),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        visualDensity: VisualDensity.compact,
      );
    }

    final siguiente = _siguiente(sobre.estado)!;
    return ActionChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      backgroundColor: color.withAlpha(25),
      side: BorderSide(color: color.withAlpha(80)),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      tooltip: 'Marcar como ${_estadoLabel(siguiente)}',
      onPressed: onAvanzar,
    );
  }
}

// ─── Widgets de detalle ───────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SubHeader(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      );
}

class _ItemRow extends StatelessWidget {
  final String label;
  final String value;

  const _ItemRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ResRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;
  final bool bold;

  const _ResRow(this.label, this.value, this.theme,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: bold ? FontWeight.w700 : null,
                )),
            Text(value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: valueColor, fontWeight: bold ? FontWeight.w700 : null)),
          ],
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text('Sin sobres cerrados',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Los sobres cerrados aparecerán acá',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}
