import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

class AssetIcons {
  static SvgPicture dryerIcon(BuildContext context) {
    return SvgPicture.asset(
      'assets/dryer.svg',
      colorFilter: ColorFilter.mode(
        Theme.of(context).primaryColor,
        BlendMode.srcIn,
      ),
      width: 28,
    );
  }

  static SvgPicture washerIcon(BuildContext context) {
    return SvgPicture.asset(
      'assets/washer.svg',
      colorFilter: ColorFilter.mode(
        Theme.of(context).primaryColor,
        BlendMode.srcIn,
      ),
      width: 28,
    );
  }
}
