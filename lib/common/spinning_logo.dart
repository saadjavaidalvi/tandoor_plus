import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';

class SpinningLogo extends StatelessWidget {
  final String name;
  final double width;
  final double height;

  SpinningLogo(
      {this.name: "assets/images/loading_placeholder.png",
      this.width,
      this.height});

  @override
  Widget build(BuildContext context) {
    return Spin(
      key: UniqueKey(),
      child: Image.asset(
        name,
        width: width,
        height: height,
      ),
      infinite: true,
      duration: Duration(milliseconds: 1250),
    );
  }
}
