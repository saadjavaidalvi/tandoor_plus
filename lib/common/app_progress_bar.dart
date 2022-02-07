import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:user/common/spinning_logo.dart';

class AppProgressBar extends StatelessWidget {
  final bool visible;
  final bool showBackground;

  AppProgressBar({
    this.visible: true,
    this.showBackground: true,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Container(
        color:
        showBackground ? Colors.grey.withOpacity(0.4) : Colors.transparent,
        width: MediaQuery
            .of(context)
            .size
            .width,
        height: MediaQuery
            .of(context)
            .size
            .height,
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            child: SpinningLogo(name: "assets/launcher/foreground.png"),
          ),
        ),
      ),
    );
  }
}
