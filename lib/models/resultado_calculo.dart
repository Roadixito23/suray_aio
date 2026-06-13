class ResultadoCalculo {
  final int boletos;
  final double totalPesos;

  const ResultadoCalculo({
    required this.boletos,
    required this.totalPesos,
  });

  factory ResultadoCalculo.calcular({
    required double precioPorBoleto,
    required int primerTalonario,
    required int ultimoTalonario,
  }) {
    final boletos = ultimoTalonario - primerTalonario + 1;
    return ResultadoCalculo(
      boletos: boletos,
      totalPesos: boletos * precioPorBoleto,
    );
  }
}
