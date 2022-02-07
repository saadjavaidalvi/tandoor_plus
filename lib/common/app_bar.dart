import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/shared.dart';

AppBar getAppBar(
  BuildContext context,
  AppBarType appBarType, {
      String title,
      bool centerTitle,
      String buttonText,
      bool backButtonEnabled = true,
      Widget leadingWidget,
      void Function() onBackPressed,
      void Function() onButtonPressed,
      Color backgroundColor = Colors.white,
      Color iconsColor = Colors.black,
      Widget trailing,
    }) {
  if (appBarType == AppBarType.backOnly) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: title != null
          ? Text(
              title,
              style: AppTextStyle.copyWith(fontWeight: FontWeight.bold),
            )
          : null,
      elevation: 0.0,
      centerTitle: centerTitle,
      leading: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: onBackPressed,
        child: Icon(
          Icons.arrow_back,
          color: iconsColor,
        ),
      ),
      actions: [
        Visibility(
          visible: trailing != null,
          child: trailing ?? Container(),
        ),
        VTDivider(),
      ],
    );
  } else if (appBarType == AppBarType.backWithButton ||
      appBarType == AppBarType.backWithWidget) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: title != null
          ? Text(
              title,
              style: AppTextStyle.copyWith(fontWeight: FontWeight.bold),
            )
          : null,
      elevation: 0.0,
      centerTitle: centerTitle,
      leading: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: onBackPressed,
        child: Icon(
          Icons.arrow_back,
          color: iconsColor,
        ),
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              highlightColor: Colors.transparent,
              splashColor: backButtonEnabled
                  ? appPrimaryColor.withOpacity(0.3)
                  : Colors.transparent,
              onTap: buttonText == null && leadingWidget == null
                  ? null
                  : onButtonPressed,
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: appBarType == AppBarType.backWithButton
                      ? Opacity(
                          opacity: backButtonEnabled ? 1 : 0.4,
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              fontSize: 16,
                              color: appPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : leadingWidget),
            ),
          ],
        ),
        Visibility(
          visible: trailing != null,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: trailing ?? Container(),
          ),
        ),
      ],
    );
  }
  return AppBar();
}

enum AppBarType { backOnly, backWithButton, backWithWidget }
