import 'package:flutter/material.dart';

import '../models/resultado_calculo.dart';
import '../widgets/resultado_card.dart';
import '../widgets/talonario_form.dart';
import 'pos_screen.dart';

class CalculadoraScreen extends StatelessWidget {
  const CalculadoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calculadora de Talonarios'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.calculate_outlined),
                text: 'Calculadora',
              ),
              Tab(
                icon: Icon(Icons.point_of_sale_outlined),
                text: 'POS',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CalculadoraTab(),
            PosScreen(),
          ],
        ),
      ),
    );
  }
}

class _CalculadoraTab extends StatefulWidget {
  const _CalculadoraTab();

  @override
  State<_CalculadoraTab> createState() => _CalculadoraTabState();
}

class _CalculadoraTabState extends State<_CalculadoraTab> {
  ResultadoCalculo? _resultado;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TalonarioForm(
            onCalcular: (resultado) {
              setState(() => _resultado = resultado);
            },
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 24),
            ResultadoCard(resultado: _resultado!),
          ],
        ],
      ),
    );
  }
}
