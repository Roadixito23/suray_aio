import 'package:flutter/material.dart';

import '../models/resultado_calculo.dart';
import '../utils/currency_formatter.dart';

class ResultadoCard extends StatelessWidget {
  final ResultadoCalculo resultado;

  const ResultadoCard({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _FilaResultado(
              icon: Icons.confirmation_number_outlined,
              label: 'Cantidad de boletos',
              valor: formatNumber(resultado.boletos),
              color: colorScheme.secondary,
            ),
            const Divider(height: 20),
            _FilaResultado(
              icon: Icons.payments_outlined,
              label: 'Total recaudado',
              valor: formatPesos(resultado.totalPesos),
              color: colorScheme.primary,
              destacado: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaResultado extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color color;
  final bool destacado;

  const _FilaResultado({
    required this.icon,
    required this.label,
    required this.valor,
    required this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          valor,
          style: destacado
              ? theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                )
              : theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
