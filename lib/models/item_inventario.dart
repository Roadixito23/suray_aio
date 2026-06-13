import 'tipo_talonario.dart';

enum EstadoInventario { enStock, porRendir }

class ItemInventario {
  final String id;
  final TipoTalonario tipo;
  final String numero;
  final EstadoInventario estado;

  const ItemInventario({
    required this.id,
    required this.tipo,
    required this.numero,
    this.estado = EstadoInventario.enStock,
  });

  ItemInventario copyWith({
    TipoTalonario? tipo,
    String? numero,
    EstadoInventario? estado,
  }) => ItemInventario(
    id: id,
    tipo: tipo ?? this.tipo,
    numero: numero ?? this.numero,
    estado: estado ?? this.estado,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero': numero,
    'tipoId': tipo.id,
    'estado': estado.name,
  };

  static ItemInventario fromJson(
    Map<String, dynamic> json,
    List<TipoTalonario> tipos,
  ) {
    final tipoId = json['tipoId'] as String;
    final tipo = tipos.firstWhere((t) => t.id == tipoId);
    final estadoStr = json['estado'] as String?;
    final estado = EstadoInventario.values.firstWhere(
      (e) => e.name == estadoStr,
      orElse: () => EstadoInventario.enStock,
    );
    return ItemInventario(
      id: json['id'] as String,
      numero: json['numero'] as String,
      tipo: tipo,
      estado: estado,
    );
  }
}
