import 'package:flutter/material.dart';
import 'package:user/common/marquee_widget.dart';
import 'package:user/common/quantity_counter.dart';
import 'package:user/common/shared.dart';

class ProductCardWidget extends StatefulWidget {
  final String itemId;
  final String nameEnglish;
  final String subTitle;
  final String image;
  final double price;
  final int quantity;
  final void Function(
    String itemId,
    int quantity,
    Function performChange,
  ) quantityChanged;
  final bool isSquareImage;
  final Color subTitleColor;

  ProductCardWidget(
    this.itemId,
    this.nameEnglish,
    this.subTitle,
    this.image,
    this.price,
    this.quantity,
    this.quantityChanged,
    this.isSquareImage, [
    this.subTitleColor = Colors.black38,
  ]) : super(key: UniqueKey());

  @override
  _ProductCardWidget createState() => _ProductCardWidget();
}

class _ProductCardWidget extends State<ProductCardWidget> {
  int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.quantity;
  }

  void plus() {
    widget.quantityChanged(widget.itemId, quantity + 1, () {
      setState(() {
        quantity++;
      });
    });
  }

  void minus() {
    if (quantity > 0) {
      widget.quantityChanged(widget.itemId, quantity - 1, () {
        setState(() {
          quantity--;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String image = (widget.image ?? "").length == 0
        ? "assets/launcher/foreground.png"
        : widget.image;

    return Column(
      children: [
        GestureDetector(
          onTap: quantity > 0 ? plus : null,
          child: Container(
            margin: const EdgeInsets.only(left: 3, right: 3, top: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              border: quantity == 0
                  ? null
                  : Border.all(color: appPrimaryColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.15),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                  child: AspectRatio(
                    aspectRatio: widget.isSquareImage ? 1 : 1.32,
                    child: image.startsWith("http")
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Divider(
                  height: 0,
                  color: Colors.black.withOpacity(.1),
                  thickness: 1,
                ),
                Container(
                  margin: const EdgeInsets.all(7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarqueeWidget(
                        child: Text(
                          widget.nameEnglish,
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: getARFontSize(context, NormalSize.S_16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      MarqueeWidget(
                        child: Text(
                          widget.subTitle,
                          style: TextStyle(
                            color: widget.subTitleColor,
                            fontSize: getARFontSize(context, NormalSize.S_14),
                          ),
                        ),
                      ),
                      Divider(
                        color: Colors.transparent,
                        height: 5,
                      ),
                      Row(
                        children: [
                          Text(
                            "Rs. ${widget.price.toStringAsFixed(widget.price.truncateToDouble() == widget.price ? 0 : 2)}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: getARFontSize(context, NormalSize.S_12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          QuantityCounter(
                            quantity: quantity,
                            onMinus: minus,
                            onPlus: plus,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: Container())
      ],
    );
  }
}
