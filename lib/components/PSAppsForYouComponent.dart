import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:playstore_flutter/model/PSModel.dart';
import 'package:playstore_flutter/screens/PSDetailScreen.dart';
import 'package:playstore_flutter/utils/AppWidget.dart';
import 'package:playstore_flutter/widgets/install_button.dart';

class PSAppsForYouComponent extends StatelessWidget {
  final PSGameModel data;

  PSAppsForYouComponent(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commonCacheImageWidget(data.imgMain, height: 100, fit: BoxFit.cover).cornerRadiusWithClipRRect(10).onTap(() {
            PSDetailScreen(data: data).launch(context);
          }),
          4.height,
          Text(data.title ?? '', style: primaryTextStyle(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${(data.appSize ?? 0).toStringAsFixed(1)}MB', style: secondaryTextStyle(size: 10)),
          4.height,
          InstallButton(app: data, size: InstallButtonSize.small),
        ],
      ).paddingOnly(left: 8, right: 8),
    );
  }
}
