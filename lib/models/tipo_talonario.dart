import 'categoria_talonario.dart';

class TipoTalonario {
  final String id;
  final int boletos;
  final double precio;
  final CategoriaTalonario categoria;
  final bool esPredefinido;

  const TipoTalonario({
    required this.id,
    required this.boletos,
    required this.precio,
    required this.categoria,
    this.esPredefinido = false,
  });

  static const List<TipoTalonario> predefinidos = [
    TipoTalonario(
      id: '_pre1',
      boletos: 50,
      precio: 3600,
      categoria: CategoriaTalonario.rojo,
      esPredefinido: true,
    ),
    TipoTalonario(
      id: '_pre2',
      boletos: 50,
      precio: 2500,
      categoria: CategoriaTalonario.verde,
      esPredefinido: true,
    ),
    TipoTalonario(
      id: '_pre3',
      boletos: 50,
      precio: 1800,
      categoria: CategoriaTalonario.azul,
      esPredefinido: true,
    ),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'boletos': boletos,
    'precio': precio,
    'categoriaId': categoria.id,
    'esPredefinido': esPredefinido,
  };

  static TipoTalonario fromJson(
    Map<String, dynamic> json,
    List<CategoriaTalonario> categorias,
  ) {
    final catId = json['categoriaId'] as String;
    final cat = categorias.firstWhere(
      (c) => c.id == catId,
      orElse: () => CategoriaTalonario.lunesASabado,
    );
    return TipoTalonario(
      id: json['id'] as String,
      boletos: json['boletos'] as int,
      precio: (json['precio'] as num).toDouble(),
      categoria: cat,
      esPredefinido: json['esPredefinido'] as bool? ?? false,
    );
  }
}
