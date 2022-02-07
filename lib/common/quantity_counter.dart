import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:user/common/shared.dart';

class QuantityCounter extends StatelessWidget {
  final int quantity;
  final Function onMinus;
  final Function onPlus;

  QuantityCounter({
    this.quantity = 0,
    @required this.onMinus,
    @required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onMinus,
          child: Image.asset(
            quantity == 0
                ? "assets/icons/ic_q_minus.png"
                : "assets/icons/ic_q_minus_active.png",
            width: MediaQuery
                .of(context)
                .size
                .width * 0.07,
            height: MediaQuery
                .of(context)
                .size
                .width * 0.07,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "$quantity",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: getARFontSize(context, NormalSize.S_14)),
          ),
        ),
        GestureDetector(
          onTap: onPlus,
          child: Image.asset(
            "assets/icons/ic_q_plus.png",
            width: MediaQuery
                .of(context)
                .size
                .width * 0.07,
            height: MediaQuery
                .of(context)
                .size
                .width * 0.07,
          ),
        ),
      ],
    );
  }
}
