import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TitleListTile extends ListTileTemplate {
  TitleListTile(String title, {Function onBack})
      : super(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          leadingIcon: Icons.arrow_back,
          onTapLeading: onBack,
        );
}

class LabelListTitle extends ListTileTemplate {
  LabelListTitle(String title, Color color)
      : super(
          title: Text(
            title,
            style: TextStyle(color: color),
          ),
          dense: true,
        );
}

class SelectionListTitle extends ListTileTemplate {
  SelectionListTitle(
    String title, {
    Function onTap,
    String leadingImage,
    IconData leadingIcon,
    Color fontColor,
  }) : super(
          title: Text(
            title,
            style: fontColor == null ? null : TextStyle(color: fontColor),
          ),
          leadingImage: leadingImage,
          leadingIcon: leadingIcon,
          onTap: onTap,
        );
}

class DisabledListTitle extends ListTileTemplate {
  DisabledListTitle(String title, String leadingImage)
      : super(
          title: Text(title),
          leadingImage: leadingImage,
          opacity: 0.4,
        );
}

class ListTileTemplate extends StatelessWidget {
  final Widget title;
  final bool dense;
  final String leadingImage;
  final IconData leadingIcon;
  final Function onTap;
  final Function onTapLeading;
  final double opacity;

  ListTileTemplate({
    this.title,
    this.onTap,
    this.dense,
    this.leadingImage,
    this.leadingIcon,
    this.onTapLeading,
    this.opacity,
  });

  Widget getLeadingWidget() {
    Widget leading;

    if (leadingIcon != null) {
      leading = Icon(
        leadingIcon,
        size: 20,
      );
    } else if (leadingImage != null) {
      leading = Image.asset(
        leadingImage,
        width: 20,
      );
    }

    if (leading != null && onTapLeading != null) {
      leading = GestureDetector(
        onTap: onTapLeading,
        child: leading,
      );
    }

    return leading;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity ?? 1,
      child: ListTile(
        title: title,
        onTap: onTap,
        dense: dense,
        leading: getLeadingWidget(),
      ),
    );
  }
}
