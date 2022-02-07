import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TDivider extends StatelessWidget {
  final double height;

  TDivider({this.height: 16});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.transparent,
      height: height,
    );
  }
}

class DoubleTDivider extends StatelessWidget {
  final double height;

  DoubleTDivider({this.height: 32});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.transparent,
      height: height,
    );
  }
}

class VTDivider extends StatelessWidget {
  final double width;

  VTDivider({this.width: 16});

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      color: Colors.transparent,
      width: width,
    );
  }
}

class VDoubleTDivider extends StatelessWidget {
  final double width;

  VDoubleTDivider({this.width: 32});

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      color: Colors.transparent,
      width: width,
    );
  }
}
