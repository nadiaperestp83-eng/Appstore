import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'cached_store_app.dart';
import '../models/store_app.dart';

class IsarCacheException implements Exception {
  final String message;
  IsarCacheException(this.message);
  @override
  String toString() => 'IsarCacheException: $message';
}

/// Camada de cache local usando Isar. Evita rebaixar o index-v2.json
/// (pesado) e refazer chamadas ao GitHub a cada abertura da loja.
class IsarCacheService {
  static Isar? _isar;

  static Future<Isar> _instance() async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    try {
      final dir = await getApplicationSupportDirectory();
      _isar = await Isar.open(
        [CachedStoreAppSchema],
        directory: dir.path,
        inspector: false,
      );
      return _isar!;
    } catch (e) {
      throw IsarCacheException('Falha ao abrir banco Isar: $e');
    }
  }

  /// Retorna apps em cache se ainda estiverem dentro de [maxAge].
  /// Retorna null se o cache estiver vazio ou expirado (sinal para buscar dados novos).
  static Future<List<StoreApp>?> getFresh({
    Duration maxAge = const Duration(hours: 6),
  }) async {
    try {
      final isar = await _instance();
      final cached = await isar.cachedStoreApps.where().findAll();
      if (cached.isEmpty) return null;

      final oldest = cached.map((c) => c.cachedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      if (DateTime.now().difference(oldest) > maxAge) return null;

      return cached.map((c) => c.toStoreApp()).toList();
    } catch (e) {
      // Cache corrompido/indisponível não deve travar a busca online.
      // ignore: avoid_print
      print('[IsarCacheService] Erro ao ler cache: $e');
      return null;
    }
  }

  static Future<void> saveAll(List<StoreApp> apps) async {
    if (apps.isEmpty) return;
    try {
      final isar = await _instance();
      await isar.writeTxn(() async {
        await isar.cachedStoreApps.clear();
        await isar.cachedStoreApps.putAll(
          apps.map(CachedStoreApp.fromStoreApp).toList(),
        );
      });
    } catch (e) {
      // ignore: avoid_print
      print('[IsarCacheService] Erro ao salvar cache: $e');
    }
  }

  static Future<void> clear() async {
    final isar = await _instance();
    await isar.writeTxn(() => isar.cachedStoreApps.clear());
  }

  static Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }
}
