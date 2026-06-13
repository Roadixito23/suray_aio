import 'package:flutter/material.dart';

import '../models/resultado_calculo.dart';
import '../widgets/resultado_card.dart';
import '../widgets/talonario_form.dart';

class CalculadoraScreen extends StatefulWidget {
  const CalculadoraScreen({super.key});

  @override
  State<CalculadoraScreen> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
  ResultadoCalculo? _resultado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de Talonarios')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TalonarioForm(
              onCalcular: (resultado) {
                setState(() => _resultado = resultado);
                // Scroll hacia resultado cuando se calcula
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () {
                    if (context.mounted) {
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                );
              },
            ),
            if (_resultado != null) ...[
              const SizedBox(height: 24),
              ResultadoCard(resultado: _resultado!),
            ],
          ],
        ),
      ),
    );
  }
}
