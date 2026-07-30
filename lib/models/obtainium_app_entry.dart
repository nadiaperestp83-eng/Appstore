/// Resultado de tentar resolver uma [ObtainiumSourceConfig]: o "tipo" de
/// fonte reconhecido e o alvo (owner/repo pra github/codeberg; a própria
/// URL pra direct/html).
class ObtainiumResolution {
  /// 'github', 'codeberg', 'direct' (link .apk direto) ou 'html' (página
  /// genérica com link pra .apk - o fallback do próprio Obtainium pra
  /// qualquer URL que não bata com nenhuma fonte conhecida).
  final String kind;
  final String target;

  ObtainiumResolution(this.kind, this.target);
}

/// Uma "config" de fonte dentro de um app do catálogo do Obtainium.
/// Cada app pode ter mais de uma (ex: versão estável + nightly, ou fontes
/// alternativas) - ver [ObtainiumAppEntry.configs].
class ObtainiumSourceConfig {
  final String url;

  /// Quando presente, o Obtainium usa esse tipo de fonte em vez de
  /// detectar pela URL (ex: um valor que indique GitLab, uma loja de app
  /// regional, Jenkins etc.). Quando é null, a fonte real é inferida pela
  /// própria URL.
  final String? overrideSource;

  ObtainiumSourceConfig({required this.url, this.overrideSource});

  /// Tenta reconhecer essa config como uma das 4 fontes que este app sabe
  /// resolver de verdade nesta versão: GitHub, Codeberg, link direto de
  /// .apk, ou uma página HTML genérica com link(s) pra .apk (fallback).
  /// Qualquer outra coisa (GitLab, lojas de app regionais, Jenkins,
  /// Telegram, F-Droid/IzzyOnDroid marcados explicitamente, etc.) retorna
  /// null - essas continuam fora até serem implementadas com um motor
  /// próprio.
  ObtainiumResolution? get resolution {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return null;

    final override = overrideSource?.toLowerCase().trim();

    // Link direto de .apk: nem precisa de override, a própria URL já é
    // o arquivo final.
    if (override == 'direct' || override == 'directapklink' || trimmedUrl.toLowerCase().endsWith('.apk')) {
      return ObtainiumResolution('direct', trimmedUrl);
    }

    final githubMatch = RegExp(r'github\.com/([^/\s]+)/([^/\s]+?)(?:\.git)?/?$').firstMatch(trimmedUrl);
    if (githubMatch != null && (override == null || override.isEmpty || override == 'github')) {
      return ObtainiumResolution('github', '${githubMatch.group(1)}/${githubMatch.group(2)}');
    }

    final codebergMatch = RegExp(r'codeberg\.org/([^/\s]+)/([^/\s]+?)(?:\.git)?/?$').firstMatch(trimmedUrl);
    if (codebergMatch != null && (override == null || override.isEmpty || override == 'codeberg')) {
      return ObtainiumResolution('codeberg', '${codebergMatch.group(1)}/${codebergMatch.group(2)}');
    }

    // overrideSource aponta explicitamente pra uma fonte que não é
    // nenhuma das 4 suportadas (GitLab, lojas regionais, Jenkins, etc.).
    if (override != null && override.isNotEmpty && override != 'html') {
      return null;
    }

    // Sobrou: nem github/codeberg reconhecidos, nem uma fonte específica
    // não suportada marcada - é exatamente o fallback "HTML" do próprio
    // Obtainium (qualquer outra URL que devolva uma página com link de
    // .apk).
    if (trimmedUrl.startsWith('http')) {
      return ObtainiumResolution('html', trimmedUrl);
    }

    return null;
  }
}

/// Um app do catálogo comunitário do Obtainium
/// (github.com/ImranR98/apps.obtainium.imranr.dev), montado a partir do
/// arquivo `data/apps/<id>.json` real desse repositório.
class ObtainiumAppEntry {
  /// Nome do arquivo sem `.json` (quase sempre o packageName Android real,
  /// ex: "com.retroarch").
  final String id;
  final String name;
  final String iconUrl;

  /// Slugs de categoria REAIS do site (ex: "games", "finance",
  /// "sports_and_health") - não inventados por nós.
  final List<String> categories;
  final String description;
  final List<ObtainiumSourceConfig> configs;

  ObtainiumAppEntry({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.categories,
    required this.description,
    required this.configs,
  });

  factory ObtainiumAppEntry.fromJson(String id, Map<String, dynamic> json) {
    final configsJson = (json['configs'] as List?) ?? const [];

    final descriptionJson = json['description'];
    String description = '';
    if (descriptionJson is Map && descriptionJson.isNotEmpty) {
      final en = descriptionJson['en'];
      description = (en is String && en.isNotEmpty) ? en : descriptionJson.values.first.toString();
    } else if (descriptionJson is String) {
      description = descriptionJson;
    }

    final firstConfig = configsJson.isNotEmpty && configsJson.first is Map ? configsJson.first as Map : null;

    return ObtainiumAppEntry(
      id: id,
      name: (firstConfig?['name'] as String?)?.trim().isNotEmpty == true ? (firstConfig!['name'] as String).trim() : id,
      iconUrl: (json['icon'] as String?) ?? '',
      categories: ((json['categories'] as List?) ?? const []).map((c) => c.toString()).toList(),
      description: description,
      configs: configsJson
          .whereType<Map>()
          .map((c) => ObtainiumSourceConfig(
                url: (c['url'] as String?) ?? '',
                overrideSource: c['overrideSource'] as String?,
              ))
          .toList(),
    );
  }

  /// A primeira config (na ordem em que o Obtainium as lista) que resolve
  /// pra uma das 4 fontes suportadas, se existir.
  ObtainiumResolution? get firstResolution {
    for (final config in configs) {
      final resolved = config.resolution;
      if (resolved != null) return resolved;
    }
    return null;
  }
}
