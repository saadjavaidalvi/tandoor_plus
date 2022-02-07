import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartButton extends StatelessWidget {
  final Function onTap;
  final int quantity;

  CartButton({
    this.onTap,
    this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.topEnd,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: quantity == 0 ? Colors.white : Color(0xFF202020),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: quantity == 0
                      ? Colors.black.withOpacity(.1)
                      : Color(0xFF1A1A1A).withOpacity(.6),
                  blurRadius: quantity == 0 ? 6 : 8,
                  offset: Offset(0, quantity == 0 ? 3 : 2),
                ),
              ],
            ),
            child: Opacity(
              opacity: quantity == 0 ? 0.5 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Image.asset(
                      quantity == 0
                          ? "assets/icons/ic_cart_empty.png"
                          : "assets/icons/ic_cart.png",
                      width: 28,
                    ),
                  ),
                  Text(
                    "Cart",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: quantity == 0 ? Colors.black : Colors.white),
                  )
                ],
              ),
            ),
          ),
          Visibility(
            visible: quantity != 0,
            child: Positioned(
              top: -8,
              right: -5,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.15),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 1,
                      bottom: 2,
                    ),
                    child: Text(
                      "$quantity",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: GoogleFonts.lato().fontFamily),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
