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
  });

  bool get isRealApp => packageName != null;
  bool get hasMultipleSources => (availableSourceOptions?.length ?? 0) > 1;
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
