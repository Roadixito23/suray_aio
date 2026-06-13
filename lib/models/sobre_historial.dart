enum EstadoSobre { noEnviado, enviado, timbrado }

class SobreTalSnap {
  final String numero;
  final int boletos;
  final double precio;

  const SobreTalSnap({required this.numero, required this.boletos, required this.precio});

  double get total => boletos * precio;

  Map<String, dynamic> toJson() => {'numero': numero, 'boletos': boletos, 'precio': precio};

  factory SobreTalSnap.fromJson(Map<String, dynamic> j) => SobreTalSnap(
        numero: j['numero'] as String,
        boletos: j['boletos'] as int,
        precio: (j['precio'] as num).toDouble(),
      );
}

class SobreVoucherSnap {
  final DateTime fecha;
  final double total;
  final String turno;

  const SobreVoucherSnap({required this.fecha, required this.total, required this.turno});

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'total': total,
        'turno': turno,
      };

  factory SobreVoucherSnap.fromJson(Map<String, dynamic> j) => SobreVoucherSnap(
        fecha: DateTime.parse(j['fecha'] as String),
        total: (j['total'] as num).toDouble(),
        turno: j['turno'] as String,
      );
}

class SobreCombSnap {
  final DateTime fecha;
  final double total;
  final String chofer;
  final String numeroMaquina;
  final String patente;

  const SobreCombSnap({
    required this.fecha,
    required this.total,
    required this.chofer,
    required this.numeroMaquina,
    required this.patente,
  });

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'total': total,
        'chofer': chofer,
        'numeroMaquina': numeroMaquina,
        'patente': patente,
      };

  factory SobreCombSnap.fromJson(Map<String, dynamic> j) => SobreCombSnap(
        fecha: DateTime.parse(j['fecha'] as String),
        total: (j['total'] as num).toDouble(),
        chofer: j['chofer'] as String,
        numeroMaquina: j['numeroMaquina'] as String,
        patente: j['patente'] as String,
      );
}

class SobreOtroSnap {
  final DateTime fecha;
  final double total;
  final String descripcion;

  const SobreOtroSnap({required this.fecha, required this.total, required this.descripcion});

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'total': total,
        'descripcion': descripcion,
      };

  factory SobreOtroSnap.fromJson(Map<String, dynamic> j) => SobreOtroSnap(
        fecha: DateTime.parse(j['fecha'] as String),
        total: (j['total'] as num).toDouble(),
        descripcion: j['descripcion'] as String,
      );
}

class SobreHistorial {
  final String id;
  final DateTime fechaCierre;
  final List<SobreTalSnap> talonarios;
  final List<SobreVoucherSnap> vouchers;
  final List<SobreCombSnap> combustibles;
  final List<SobreOtroSnap> otros;
  final double totalTalonarios;
  final double totalVouchers;
  final double totalCombustible;
  final double totalOtros;
  final double efectivo;
  final EstadoSobre estado;

  const SobreHistorial({
    required this.id,
    required this.fechaCierre,
    required this.talonarios,
    required this.vouchers,
    required this.combustibles,
    required this.otros,
    required this.totalTalonarios,
    required this.totalVouchers,
    required this.totalCombustible,
    required this.totalOtros,
    required this.efectivo,
    required this.estado,
  });

  SobreHistorial copyWith({EstadoSobre? estado}) => SobreHistorial(
        id: id,
        fechaCierre: fechaCierre,
        talonarios: talonarios,
        vouchers: vouchers,
        combustibles: combustibles,
        otros: otros,
        totalTalonarios: totalTalonarios,
        totalVouchers: totalVouchers,
        totalCombustible: totalCombustible,
        totalOtros: totalOtros,
        efectivo: efectivo,
        estado: estado ?? this.estado,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fechaCierre': fechaCierre.toIso8601String(),
        'talonarios': talonarios.map((t) => t.toJson()).toList(),
        'vouchers': vouchers.map((v) => v.toJson()).toList(),
        'combustibles': combustibles.map((c) => c.toJson()).toList(),
        'otros': otros.map((o) => o.toJson()).toList(),
        'totalTalonarios': totalTalonarios,
        'totalVouchers': totalVouchers,
        'totalCombustible': totalCombustible,
        'totalOtros': totalOtros,
        'efectivo': efectivo,
        'estado': estado.name,
      };

  factory SobreHistorial.fromJson(Map<String, dynamic> j) => SobreHistorial(
        id: j['id'] as String,
        fechaCierre: DateTime.parse(j['fechaCierre'] as String),
        talonarios: (j['talonarios'] as List)
            .map((e) => SobreTalSnap.fromJson(e as Map<String, dynamic>))
            .toList(),
        vouchers: (j['vouchers'] as List)
            .map((e) => SobreVoucherSnap.fromJson(e as Map<String, dynamic>))
            .toList(),
        combustibles: (j['combustibles'] as List)
            .map((e) => SobreCombSnap.fromJson(e as Map<String, dynamic>))
            .toList(),
        otros: (j['otros'] as List)
            .map((e) => SobreOtroSnap.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalTalonarios: (j['totalTalonarios'] as num).toDouble(),
        totalVouchers: (j['totalVouchers'] as num).toDouble(),
        totalCombustible: (j['totalCombustible'] as num).toDouble(),
        totalOtros: (j['totalOtros'] as num).toDouble(),
        efectivo: (j['efectivo'] as num).toDouble(),
        estado: EstadoSobre.values.firstWhere(
          (e) => e.name == j['estado'],
          orElse: () => EstadoSobre.noEnviado,
        ),
      );
}
