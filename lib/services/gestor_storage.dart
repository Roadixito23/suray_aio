import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/categoria_talonario.dart';
import '../models/control_caja.dart';
import '../models/item_inventario.dart';
import '../models/sobre_historial.dart';
import '../models/talonario.dart';
import '../models/tipo_talonario.dart';

class GestorStorage {
  static const _kCategorias = 'gestor_categorias';
  static const _kTipos = 'gestor_tipos';
  static const _kTalonarios = 'gestor_talonarios';
  static const _kInventario = 'gestor_inventario';
  static const _kHistorial = 'gestor_historial';

  // ── Categorías ─────────────────────────────────────────────────────────────

  static Future<void> guardarCategorias(
    List<CategoriaTalonario> categorias,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kCategorias,
      jsonEncode(categorias.map((c) => c.toJson()).toList()),
    );
  }

  static Future<List<CategoriaTalonario>> cargarCategorias() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCategorias);
    if (raw == null) return List.of(CategoriaTalonario.predefinidas);
    return (jsonDecode(raw) as List)
        .map((j) => CategoriaTalonario.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Tipos ──────────────────────────────────────────────────────────────────

  static Future<void> guardarTipos(List<TipoTalonario> tipos) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kTipos,
      jsonEncode(tipos.map((t) => t.toJson()).toList()),
    );
  }

  static Future<List<TipoTalonario>> cargarTipos(
    List<CategoriaTalonario> categorias,
  ) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kTipos);
    if (raw == null) return List.of(TipoTalonario.predefinidos);
    return (jsonDecode(raw) as List)
        .map(
          (j) => TipoTalonario.fromJson(j as Map<String, dynamic>, categorias),
        )
        .toList();
  }

  // ── Talonarios ─────────────────────────────────────────────────────────────

  static Future<void> guardarTalonarios(List<Talonario> talonarios) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kTalonarios,
      jsonEncode(talonarios.map((t) => t.toJson()).toList()),
    );
  }

  static Future<List<Talonario>> cargarTalonarios(
    List<TipoTalonario> tipos,
  ) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kTalonarios);
    if (raw == null) return [];
    final result = <Talonario>[];
    for (final j in jsonDecode(raw) as List) {
      try {
        result.add(Talonario.fromJson(j as Map<String, dynamic>, tipos));
      } catch (_) {
        // Omitir talonarios cuyo tipo ya no existe
      }
    }
    return result;
  }

  // ── Inventario ─────────────────────────────────────────────────────────────

  static Future<void> guardarInventario(List<ItemInventario> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kInventario,
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }

  static Future<List<ItemInventario>> cargarInventario(
    List<TipoTalonario> tipos,
  ) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kInventario);
    if (raw == null) return [];
    final result = <ItemInventario>[];
    for (final j in jsonDecode(raw) as List) {
      try {
        result.add(ItemInventario.fromJson(j as Map<String, dynamic>, tipos));
      } catch (_) {
        // Omitir items cuyo tipo ya no existe
      }
    }
    return result;
  }

  // ── Historial ──────────────────────────────────────────────────────────────

  static Future<void> guardarHistorial(List<SobreHistorial> historial) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kHistorial,
      jsonEncode(historial.map((s) => s.toJson()).toList()),
    );
  }

  static Future<List<SobreHistorial>> cargarHistorial() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kHistorial);
    if (raw == null) return [];
    final result = <SobreHistorial>[];
    for (final j in jsonDecode(raw) as List) {
      try {
        result.add(SobreHistorial.fromJson(j as Map<String, dynamic>));
      } catch (_) {}
    }
    return result;
  }

  // ── Control de Caja ────────────────────────────────────────────────────────

  static const _kControlCaja = 'gestor_control_caja';

  static Future<void> guardarControlCaja(List<ControlCaja> controles) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kControlCaja,
      jsonEncode(controles.map((c) => c.toJson()).toList()),
    );
  }

  static Future<List<ControlCaja>> cargarControlCaja() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kControlCaja);
    if (raw == null) return [];
    final result = <ControlCaja>[];
    for (final j in jsonDecode(raw) as List) {
      try {
        result.add(ControlCaja.fromJson(j as Map<String, dynamic>));
      } catch (_) {}
    }
    return result;
  }
}
