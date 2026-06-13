import 'tipo_talonario.dart';

class Talonario {
  final String id;
  final String numero;
  final TipoTalonario tipo;

  const Talonario({
    required this.id,
    required this.numero,
    required this.tipo,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero': numero,
    'tipoId': tipo.id,
  };

  static Talonario fromJson(
    Map<String, dynamic> json,
    List<TipoTalonario> tipos,
  ) {
    final tipoId = json['tipoId'] as String;
    final tipo = tipos.firstWhere((t) => t.id == tipoId);
    return Talonario(
      id: json['id'] as String,
      numero: json['numero'] as String,
      tipo: tipo,
    );
  }
}
