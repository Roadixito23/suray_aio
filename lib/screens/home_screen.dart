import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'calculadora_screen.dart';
import 'control_caja_screen.dart';
import 'gestor_screen.dart';
import 'inventario_screen.dart';
import 'rendicion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF5EEED),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            color: AppColors.azulMarino,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.burdeo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.business_center_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Suray AIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gestión de talonarios',
                      style: TextStyle(
                        color: Color(0xBBFFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Grid de módulos ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fila 1
                  Row(
                    children: [
                      Expanded(
                        child: _ModuleCard(
                          icon: Icons.calculate_outlined,
                          title: 'Calculadora',
                          subtitle: 'de Talonarios',
                          color: AppColors.hunterGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CalculadoraScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModuleCard(
                          icon: Icons.folder_copy_outlined,
                          title: 'Gestor',
                          subtitle: 'de Talonarios',
                          color: AppColors.burdeo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const GestorScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Fila 2
                  Row(
                    children: [
                      Expanded(
                        child: _ModuleCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Inventario',
                          subtitle: 'de Talonarios',
                          color: AppColors.hunterGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InventarioScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModuleCard(
                          icon: Icons.assignment_outlined,
                          title: 'Rendición',
                          subtitle: 'de Sobres',
                          color: AppColors.burdeo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RendicionScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Fila 3 – ancho completo
                  _ModuleCard(
                    icon: Icons.point_of_sale_outlined,
                    title: 'Control de Caja',
                    subtitle: 'Registro diario',
                    color: AppColors.azulMarino,
                    fullWidth: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ControlCajaScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = Color.fromRGBO(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
      0.15,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: fullWidth ? 80 : 130,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: fullWidth
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: color.withAlpha(160),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: color.withAlpha(120)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color.withAlpha(160),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
