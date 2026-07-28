import 'package:flutter/material.dart';

/// Uma fonte disponível para um app (usado no seletor "Disponível em N fontes").
class PSAppSourceOption {
  final String repoLabel;
  final String version;
  final String downloadUrl;
  final String source; // 'github' ou 'fdroid'

  PSAppSourceOption({required this.repoLabel, required this.version, required this.downloadUrl, required this.source});
}

class PSGameModel {
  String? imgMain;
  String? imgLogo;
  String? title;
  String? subTitle;
  String? subTitle1;
  double? rating;
  double? appSize;
  String? event;
  Icon? icon;
  String? ends;
  bool? install;
  List<String>? imagesData;

  // ===== Campos novos: dados reais vindos do motor (HubApp) =====
  String? packageName; // chave real do app agrupado
  String? downloadUrl; // link direto do .apk da fonte preferida, sem zip
  String? version; // versão da fonte preferida
  String? preferredRepoLabel; // nome da fonte escolhida como padrão
  List<PSAppSourceOption>? availableSourceOptions; // todas as fontes, com downloadUrl de cada uma
  String? developer;
  int? downloads;
  String? description; // descrição longa real (F-Droid/GitHub) - vazia/placeholder na Aptoide
  List<String>? categories; // categorias reais (F-Droid) - vazia na Aptoide
  int? versionCode; // usado para comparar com o instalado e saber se há atualização

  PSGameModel({
    this.imagesData,
    this.imgMain,
    this.imgLogo,
    this.title,
    this.subTitle,
    this.rating,
    this.appSize,
    this.subTitle1,
    this.event,
    this.ends,
    this.icon,
    this.install,
    this.packageName,
    this.downloadUrl,
    this.version,
    this.preferredRepoLabel,
    this.availableSourceOptions,
    this.developer,
    this.downloads,
    this.description,
    this.categories,
    this.versionCode,
  });

  bool get isRealApp => packageName != null;
  bool get hasMultipleSources => (availableSourceOptions?.length ?? 0) > 1;

  /// Descrição pronta pra exibir na tela de detalhes ("About this game").
  /// Rede de segurança: se a fonte tiver descrição real (F-Droid/GitHub),
  /// usa ela. Se vier vazia/nula (caso comum na Aptoide, cuja API pública
  /// não retorna descrição longa), monta um resumo limpo a partir do que
  /// TEMOS de real (resumo curto, categorias, desenvolvedor) - nunca mostra
  /// texto genérico do tipo "Sem descrição." pro usuário.
  String get displayDescription {
    final desc = description?.trim();
    if (desc != null && desc.isNotEmpty && desc != 'Sem descrição.') {
      return desc;
    }
    final parts = <String>[];
    if ((subTitle ?? '').trim().isNotEmpty) parts.add(subTitle!.trim());
    if ((categories ?? []).isNotEmpty) parts.add('Categoria: ${categories!.join(', ')}.');
    if ((developer ?? '').trim().isNotEmpty) parts.add('Desenvolvido por ${developer!.trim()}.');
    if (parts.isEmpty) {
      return '${(title ?? '').trim().isNotEmpty ? title!.trim() : 'Este app'} não possui uma descrição detalhada disponível nesta fonte.';
    }
    return parts.join(' ');
  }
}

class PSMyAppsModel {
  String? appLogo;
  String? title;
  String? size;
  String? subTitle;
  String? time;
  bool isUpdate;
  String? appSize;
  String? upaDteSubtitle;
  bool isExpanded;
  String? information;
  bool install;

  PSMyAppsModel({this.appLogo, this.title, this.size, this.subTitle, this.time, this.isUpdate = false, this.appSize, this.upaDteSubtitle, this.isExpanded = false, this.information, this.install = false});
}

class PSReviews {
  String? cirLogo;
  String? title;
  String? subTile;
  String? date;

  PSReviews({this.cirLogo, this.title, this.subTile, this.date});
}

class PSRadio {
  String? title;
  bool isSelected;

  PSRadio({this.title, this.isSelected = false});
}

class Categories {
  String? name;
  IconData? icon;
  bool isExpanded;

  Categories({this.name, this.icon, this.isExpanded = false});
}

class CategoriesApps {
  String? name;
  IconData? icon;

  CategoriesApps({this.name, this.icon});
}

class GenresList {
  String? name;
  IconData? icon;

  GenresList({this.name, this.icon});
}

class ReviewModel {
  String? img;
  String? name;
  String? date;
  String? review;
  double? rating;

  ReviewModel({this.img, this.name, this.date, this.rating, this.review});
}

class RattingModel {
  String? typeRating;
  IconData? star;

  RattingModel({
    this.typeRating,
    this.star,
  });
}

class GameModelList {
  String? img;
  String? videoImg;

  GameModelList({this.img, this.videoImg});
}
