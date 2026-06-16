import 'package:flutter/material.dart';

class CategoriaTalonario {
  final String id;
  final String nombre;
  final Color color;
  final bool esPredefinida;

  const CategoriaTalonario({
    required this.id,
    required this.nombre,
    required this.color,
    this.esPredefinida = false,
  });

  static const lunesASabado = CategoriaTalonario(
    id: '_pre1',
    nombre: 'Lunes a Sábado',
    color: Color(0xFF6750A4),
    esPredefinida: true,
  );

  static const rojo = CategoriaTalonario(
    id: '_pre_rojo',
    nombre: 'Rojo',
    color: Color(0xFFD32F2F),
    esPredefinida: true,
  );

  static const verde = CategoriaTalonario(
    id: '_pre_verde',
    nombre: 'Verde',
    color: Color(0xFF388E3C),
    esPredefinida: true,
  );

  static const azul = CategoriaTalonario(
    id: '_pre_azul',
    nombre: 'Azul',
    color: Color(0xFF1976D2),
    esPredefinida: true,
  );

  static const List<CategoriaTalonario> predefinidas = [
    lunesASabado,
    rojo,
    verde,
    azul,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'color': color.toARGB32(),
    'esPredefinida': esPredefinida,
  };

  factory CategoriaTalonario.fromJson(Map<String, dynamic> json) {
    final argb = json['color'] as int;
    return CategoriaTalonario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      color: Color.fromARGB(
        (argb >> 24) & 0xFF,
        (argb >> 16) & 0xFF,
        (argb >> 8) & 0xFF,
        argb & 0xFF,
      ),
      esPredefinida: json['esPredefinida'] as bool? ?? false,
    );
  }
}
