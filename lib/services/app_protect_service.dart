import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/services/native_apk_inspector.dart';
import 'package:playstore_flutter/utils/PSConstants.dart';

/// Resultado de uma verificação do App Protect sobre um .apk específico.
///
/// Importante: o ÚNICO campo que deveria, na prática, impedir uma
/// instalação é [isKnownMalware] (hash batendo com uma ameaça confirmada).
/// Tudo o mais - [sensitivePermissions], [trustedOrigin] - é só
/// informativo/transparência: a decisão final é sempre do usuário.
class AppProtectVerdict {
  /// false quando o usuário desligou o App Protect em Settings - nesse
  /// caso nenhuma checagem roda e a instalação segue direto.
  final bool enabled;

  /// true se o link de download veio de uma origem da lista branca
  /// (GitHub Releases, Codeberg, F-Droid/IzzyOnDroid, etc.).
  final bool trustedOrigin;

  /// true só se o SHA-256 do arquivo bateu com uma ameaça confirmada na
  /// lista local. Esse é o único motivo real de bloqueio.
  final bool isKnownMalware;

  /// Permissões "sensíveis" (SMS, chamadas, admin de dispositivo etc.)
  /// que o manifesto do .apk declara - só aviso, nunca bloqueio.
  final List<String> sensitivePermissions;

  final String? packageName;
  final String? versionName;

  /// Tempo real que a verificação levou - o App Protect é feito pra ser
  /// da ordem de dezenas/poucas centenas de milissegundos (não faz
  /// download extra nem chamada de rede: origem é string, hash é local,
  /// permissões vêm do Package Manager do próprio aparelho).
  final Duration elapsed;

  const AppProtectVerdict({
    required this.enabled,
    required this.trustedOrigin,
    required this.isKnownMalware,
    required this.sensitivePermissions,
    required this.elapsed,
    this.packageName,
    this.versionName,
  });

  factory AppProtectVerdict.disabled() => AppProtectVerdict(
        enabled: false,
        trustedOrigin: false,
        isKnownMalware: false,
        sensitivePermissions: const [],
        elapsed: Duration.zero,
      );

  /// Único caso em que o App Protect deveria realmente impedir a
  /// instalação.
  bool get shouldBlockInstall => enabled && isKnownMalware;

  /// true quando há algo a mostrar no aviso neutro de transparência
  /// (nunca um bloqueio).
  bool get hasTransparencyWarning => enabled && !isKnownMalware && sensitivePermissions.isNotEmpty;
}

/// "App Protect": verificação rápida e leve de um .apk antes de instalar,
/// em duas camadas -
///
/// 1. Camada rápida (Flutter/Dart): confere a origem do link contra uma
///    lista branca de domínios conhecidos, calcula o SHA-256 do arquivo
///    contra uma lista local de ameaças confirmadas. Tudo local, sem
///    round-trip de rede - da ordem de milissegundos.
/// 2. Camada nativa (Android Package Manager): pergunta pro sistema
///    operacional, via [NativeApkInspector], quais permissões o .apk
///    declara - o mesmo mecanismo que o instalador nativo do Android usa.
///
/// Filosofia (pedido explícito do projeto): isto NUNCA verifica ou exige
/// keystore/assinatura. APKs de debug, forks, builds locais (inclusive
/// compilados no próprio celular) passam sem nenhum alerta de "app
/// modificado" - o único jeito de esta verificação realmente impedir uma
/// instalação é o hash bater com uma ameaça CONFIRMADA. Todo o resto
/// (permissões sensíveis, origem desconhecida) é só transparência: um
/// aviso neutro, nunca uma trava.
class AppProtectService {
  AppProtectService._();
  static final AppProtectService instance = AppProtectService._();

  final NativeApkInspector _nativeInspector = NativeApkInspector();

  // ===========================================================================
  // Interruptor Ativar/Desativar (persistido)
  // ===========================================================================

  Future<bool> isEnabled() => getBool(appProtectEnabledPref, defaultValue: true);

  Future<void> setEnabled(bool value) => setBool(appProtectEnabledPref, value);

  // ===========================================================================
  // Lista branca de origens confiáveis (Camada rápida)
  // ===========================================================================

  /// Domínios cujo link de download já é considerado confiável de cara -
  /// todos são origens que hospedam builds públicas e rastreáveis (não é
  /// uma "loja fechada"): GitHub Releases, Codeberg, F-Droid oficial e
  /// IzzyOnDroid.
  static const List<String> trustedHosts = [
    'github.com',
    'objects.githubusercontent.com',
    'raw.githubusercontent.com',
    'codeberg.org',
    'f-droid.org',
    'apt.izzysoft.de',
  ];

  bool _isTrustedOrigin(String downloadUrl) {
    final host = Uri.tryParse(downloadUrl)?.host.toLowerCase() ?? '';
    return trustedHosts.any((trusted) => host == trusted || host.endsWith('.$trusted'));
  }

  // ===========================================================================
  // Hash de ameaças confirmadas (Camada rápida)
  // ===========================================================================

  /// Lista local de SHA-256 de ameaças CONFIRMADAS. Vazia por padrão - este
  /// projeto não tem acesso a um feed de inteligência de ameaças ao vivo;
  /// o hook existe pra, se um dia houver uma fonte real (ex: um endpoint
  /// interno da sua própria infraestrutura), bastar preencher/consultar
  /// aqui. Sem uma fonte real, o comportamento correto é não fingir que
  /// existe uma - por isso fica vazia, e nunca é o "falso positivo" de
  /// ninguém.
  static const Set<String> _knownMalwareSha256 = {};

  Future<String> _sha256Of(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  // ===========================================================================
  // Permissões sensíveis (aviso neutro - Camada nativa fornece os dados)
  // ===========================================================================

  /// Permissões que, se um app declarar várias delas, justificam mostrar
  /// um aviso neutro de transparência (nunca bloqueio) - o usuário decide.
  static const Set<String> _sensitivePermissions = {
    'android.permission.SEND_SMS',
    'android.permission.RECEIVE_SMS',
    'android.permission.READ_SMS',
    'android.permission.CALL_PHONE',
    'android.permission.READ_CALL_LOG',
    'android.permission.WRITE_CALL_LOG',
    'android.permission.PROCESS_OUTGOING_CALLS',
    'android.permission.BIND_DEVICE_ADMIN',
    'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.REQUEST_INSTALL_PACKAGES',
  };

  /// Quantas permissões sensíveis um app precisa declarar antes de valer a
  /// pena avisar o usuário. 1 sozinha é comum até em apps legítimos (ex:
  /// um app de chamadas real usando CALL_PHONE) - o aviso é pra quando o
  /// conjunto já chama atenção.
  static const int _sensitivePermissionThreshold = 2;

  // ===========================================================================
  // Verificação principal
  // ===========================================================================

  /// Roda as duas camadas sobre [apkFile], baixado de [downloadUrl].
  /// Se o App Protect estiver desligado (ver [isEnabled]), retorna
  /// imediatamente sem checar nada.
  Future<AppProtectVerdict> inspect({
    required String downloadUrl,
    required File apkFile,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return AppProtectVerdict.disabled();

    final stopwatch = Stopwatch()..start();

    final trustedOrigin = _isTrustedOrigin(downloadUrl);

    bool isKnownMalware = false;
    try {
      final hash = await _sha256Of(apkFile);
      isKnownMalware = _knownMalwareSha256.contains(hash);
    } catch (e) {
      // Se não der nem pra ler o arquivo pra calcular o hash, não trava a
      // instalação por causa disso - só não temos esse sinal.
      // ignore: avoid_print
      print('[AppProtectService] Falha ao calcular SHA-256: $e');
    }

    List<String> sensitiveFound = const [];
    String? packageName;
    String? versionName;
    if (!isKnownMalware) {
      // Só vale a pena perguntar pro Package Manager se o arquivo já não
      // foi barrado pelo hash - evita trabalho nativo desnecessário.
      final manifest = await _nativeInspector.inspect(apkFile.path);
      if (manifest != null) {
        packageName = manifest.packageName;
        versionName = manifest.versionName;
        final found = manifest.permissions.where(_sensitivePermissions.contains).toSet().toList();
        if (found.length >= _sensitivePermissionThreshold) {
          sensitiveFound = found;
        }
      }
    }

    stopwatch.stop();

    final verdict = AppProtectVerdict(
      enabled: true,
      trustedOrigin: trustedOrigin,
      isKnownMalware: isKnownMalware,
      sensitivePermissions: sensitiveFound,
      elapsed: stopwatch.elapsed,
      packageName: packageName,
      versionName: versionName,
    );

    await _recordScan(appLabel: packageName ?? apkFile.uri.pathSegments.last, verdict: verdict);
    return verdict;
  }

  // ===========================================================================
  // Histórico local de verificações (pra tela de App Protect mostrar dado
  // real, não mockado)
  // ===========================================================================

  static const int _maxScanHistory = 15;

  Future<void> _recordScan({required String appLabel, required AppProtectVerdict verdict}) async {
    try {
      final history = await getScanHistory();
      history.insert(0, {
        'label': appLabel,
        'trustedOrigin': verdict.trustedOrigin,
        'isKnownMalware': verdict.isKnownMalware,
        'sensitivePermissionsCount': verdict.sensitivePermissions.length,
        'elapsedMs': verdict.elapsed.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (history.length > _maxScanHistory) history.removeRange(_maxScanHistory, history.length);
      await setValue(appProtectScanHistoryPref, jsonEncode(history));
    } catch (e) {
      // ignore: avoid_print
      print('[AppProtectService] Falha ao gravar histórico de verificação: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final raw = await getStringAsync(appProtectScanHistoryPref, defaultValue: '');
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearScanHistory() => removeKey(appProtectScanHistoryPref);
}
