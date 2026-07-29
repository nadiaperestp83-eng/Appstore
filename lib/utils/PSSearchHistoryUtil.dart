import 'dart:convert';

import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/utils/PSConstants.dart';

/// Histórico local de buscas, persistido no dispositivo (SharedPreferences
/// via nb_utils). Guarda só o texto pesquisado, sem nenhum dado de rede -
/// é exatamente o que Settings > "Clear Local Search" apaga.
class PSSearchHistory {
  PSSearchHistory._();

  static const int _maxEntries = 20;

  static Future<List<String>> getAll() async {
    final raw = await getStringAsync(searchHistoryPref, defaultValue: '');
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Chamado toda vez que o usuário confirma uma busca na barra global (ver
  /// [AppScreen] em PSNavigationScreen.dart), pra que "Clear Local Search"
  /// em Settings tenha algo de verdade pra apagar.
  static Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = await getAll();
    current.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > _maxEntries) current.removeRange(_maxEntries, current.length);

    await setValue(searchHistoryPref, jsonEncode(current));
  }

  static Future<void> clear() async {
    await removeKey(searchHistoryPref);
  }
}
