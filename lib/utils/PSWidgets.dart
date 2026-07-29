import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSAppsCategoriesScreen.dart';
import 'package:playstore_flutter/screens/PSMoviesGenresScreen.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/utils/AppleColors.dart';
import 'package:playstore_flutter/utils/PSColor.dart';

Widget gameDetail({String? img, required String txtPlayType, required String txtAction, required String txtRating, required String txtSize}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: commonCacheImageWidget(img, width: 45, height: 45, fit: BoxFit.cover),
      ),
      16.width,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(txtPlayType, style: primaryTextStyle(size: 14)),
          4.height,
          Text(txtAction, style: secondaryTextStyle(size: 12)),
          4.height,
          Row(
            children: [
              Row(
                children: [
                  Text(txtRating, style: secondaryTextStyle(size: 12)),
                  Icon(Icons.star, size: 12, color: GMGreyColor),
                ],
              ),
              8.width,
              Text(txtSize, style: secondaryTextStyle(size: 12)),
            ],
          ),
        ],
      ),
    ],
  ).paddingSymmetric(horizontal: 16);
}

// ignore: must_be_immutable
class CategoriesList extends StatefulWidget {
  List<CategoriesApps>? data;
  bool isMovies;

  CategoriesList({this.data, this.isMovies = false});

  @override
  _CategoriesListState createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withOpacity(0.08) : AppleColors.backgroundSecondary.withOpacity(0.6);
    final textColor = isDark ? Colors.white : AppleColors.textPrimary;
    final iconColor = widget.isMovies ? psColorRed : AppleColors.accentBlue;

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.data!.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final item = widget.data![index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (widget.isMovies) {
              PSMoviesGenresScreen(title: item.name).launch(context);
            } else {
              PSAppsCategoriesScreen(data: item).launch(context);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: iconColor, size: 22),
                10.width,
                Expanded(
                  child: Text(
                    item.name!,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget getListView({required List<GameModelList> gameList}) {
  return Container(
    height: 190,
    child: ListView.builder(
      itemCount: gameList.length,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        GameModelList data = gameList[index];
        return Container(
          margin: EdgeInsets.only(left: 0, right: 8, top: 8, bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: commonCacheImageWidget(data.img, width: 290, fit: BoxFit.cover),
          ),
        );
      },
    ),
  );
}
