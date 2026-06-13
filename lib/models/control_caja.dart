import 'package:flutter/material.dart';

class RangoSnap {
  final int desde;
  final int hasta;

  const RangoSnap({required this.desde, required this.hasta});

  int get boletos => hasta - desde + 1;

  Map<String, dynamic> toJson() => {'desde': desde, 'hasta': hasta};

  factory RangoSnap.fromJson(Map<String, dynamic> j) =>
      RangoSnap(desde: j['desde'] as int, hasta: j['hasta'] as int);
}

class ControlCajaLinea {
  final String tipoId;
  final String descripcion;
  final String categoriaNombre;
  final Color categoriaColor;
  final double precio;
  final List<RangoSnap> rangos;

  const ControlCajaLinea({
    required this.tipoId,
    required this.descripcion,
    required this.categoriaNombre,
    required this.categoriaColor,
    required this.precio,
    required this.rangos,
  });

  int get boletosVendidos => rangos.fold(0, (s, r) => s + r.boletos);
  double get subtotal => precio * boletosVendidos;

  Map<String, dynamic> toJson() => {
        'tipoId': tipoId,
        'descripcion': descripcion,
        'categoriaNombre': categoriaNombre,
        'categoriaColor': categoriaColor.toARGB32(),
        'precio': precio,
        'rangos': rangos.map((r) => r.toJson()).toList(),
      };

  factory ControlCajaLinea.fromJson(Map<String, dynamic> j) {
    final argb = j['categoriaColor'] as int;
    return ControlCajaLinea(
      tipoId: j['tipoId'] as String,
      descripcion: j['descripcion'] as String,
      categoriaNombre: j['categoriaNombre'] as String,
      categoriaColor: Color.fromARGB(
        (argb >> 24) & 0xFF,
        (argb >> 16) & 0xFF,
        (argb >> 8) & 0xFF,
        argb & 0xFF,
      ),
      precio: (j['precio'] as num).toDouble(),
      rangos: (j['rangos'] as List)
          .map((e) => RangoSnap.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ControlCaja {
  final String id;
  final DateTime fecha;
  final List<ControlCajaLinea> lineas;

  const ControlCaja({
    required this.id,
    required this.fecha,
    required this.lineas,
  });

  double get total => lineas.fold(0, (s, l) => s + l.subtotal);
  int get totalBoletos => lineas.fold(0, (s, l) => s + l.boletosVendidos);

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'lineas': lineas.map((l) => l.toJson()).toList(),
      };

  factory ControlCaja.fromJson(Map<String, dynamic> j) => ControlCaja(
        id: j['id'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        lineas: (j['lineas'] as List)
            .map((e) => ControlCajaLinea.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
