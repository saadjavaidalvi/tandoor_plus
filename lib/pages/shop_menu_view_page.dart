import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:user/common/app_bar.dart';
import 'package:user/common/cart_button.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/product_card_widget.dart';
import 'package:user/common/shared.dart';
import 'package:user/models/cart.dart';
import 'package:user/models/order_item.dart';
import 'package:user/models/shop.dart';
import 'package:user/models/shop_menu_item.dart';
import 'package:user/pages/order_summary_page.dart';

class ShopMenuViewPage extends StatefulWidget {
  static final String route = "shop_menu_view";

  final Shop shop;
  final String categoryName;
  final List<ShopMenuItem> menuItems;

  ShopMenuViewPage(this.shop, this.categoryName, this.menuItems);

  @override
  State<ShopMenuViewPage> createState() => _ShopMenuViewPageState(menuItems);
}

class _ShopMenuViewPageState extends State<ShopMenuViewPage> {
  final List<ShopMenuItem> menuItems;

  Shop shop;
  Cart cart;

  int cartQuantity;

  String selectedTag = "";

  _ShopMenuViewPageState(this.menuItems) {
    cart = getIt.get<Cart>();
  }

  @override
  void initState() {
    super.initState();

    if (widget.shop != null)
      shop = widget.shop;
    else
      throw UnimplementedError("Method unimplemented");

    cartQuantity = cart.cartQuantity;
  }

  void replaceCartOfOtherShop(
    String itemId,
    int quantity,
    Function performChange, [
    bool clearFirst = true,
  ]) {
    if (clearFirst) cart.clear();
    cart.subCarts.add(SubCart(
      shopName: shop.nameEnglish ?? shop.nameUrdu,
      shopId: shop.id,
    ));
    quantityChanged(itemId, quantity, performChange);
  }

  void quantityChanged(
    String itemId,
    int quantity,
    Function performChange,
  ) {
    // If cart has different shop id and cartQuantity > 0, confirm from user and empty it
    if (cart.isGeneral) {
      if (cart.cartQuantity > 0) {
        showShopChangeConfirmation(
          context,
          "You already have items in your cart from another shop. Do you want to remove all other items and add this?",
          onYes: () {
            replaceCartOfOtherShop(itemId, quantity, performChange);
          },
        );
      } else {
        replaceCartOfOtherShop(itemId, quantity, performChange);
      }
    } else if (cart.subCarts.findByShopId(shop.id) == null) {
      replaceCartOfOtherShop(itemId, quantity, performChange, false);
    } else {
      Cart _cart = cart;
      SubCart subCart = _cart.subCarts.findByShopId(shop.id);

      // Remove items with quantity 0
      int i = subCart.orderItems.indexWhere((element) => element.id == itemId);

      if (i >= 0) {
        subCart.orderItems[i].quantity = quantity;
      } else {
        ShopMenuItem item = menuItems.firstWhere(
          (element) => element.id == itemId,
        );

        subCart.orderItems.add(
          OrderItem(
            id: item.id,
            quantity: quantity,
            name: item.name,
            urduName: item.name,
            price: item.price,
          ),
        );
      }
      subCart.orderItems.removeWhere(
        (element) => element.quantity <= 0 || element.price <= 0,
      );

      setState(() {
        cart = _cart;
        cartQuantity = cart.cartQuantity;
      });

      performChange?.call();
    }
  }

  void openOrderSummaryPage() async {
    if (cartQuantity > 0) {
      await Navigator.pushNamed(
        context,
        OrderSummaryPage.route,
      );

      Cart _cart = getIt.get<Cart>();
      if (_cart.subCarts.length != 0) {
        SubCart subCart = _cart.subCarts.findByShopId(shop.id);
        if (subCart != null) {
          subCart.orderItems.removeWhere(
            (element) => element.quantity <= 0 || element.price <= 0,
          );
        }

        setState(() {
          cart = _cart;
          cartQuantity = cart.cartQuantity;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = getAppBar(
      context,
      AppBarType.backOnly,
      backgroundColor: Colors.white,
      iconsColor: Colors.black87,
      onBackPressed: () => Navigator.pop(context),
      title: widget.categoryName,
    );

    List<Widget> shopItems = [];
    SubCart subCart = cart.subCarts.findByShopId(shop.id);

    for (ShopMenuItem item in menuItems ?? []) {
      if (selectedTag == "" ||
          (item.tags ?? "").split(",").contains(selectedTag)) {
        shopItems.add(
          ProductCardWidget(
            item.id,
            item.name,
            item.unit,
            item.imageUrl,
            item.price,
            subCart?.shopId == shop.id
                ? subCart?.orderItems
                        ?.firstWhere((element) => element.id == item.id,
                            orElse: () => null)
                        ?.quantity ??
                    0
                : 0,
            quantityChanged,
            true,
            Colors.black,
          ),
        );
      }
    }

    List<String> menuItemTags = [];
    menuItems.forEach((menuItem) {
      if ((menuItem.tags ?? "").length > 0) {
        menuItemTags.addAll(menuItem.tags.split(","));
        menuItem.tags.split(",").forEach((tag) {
          menuItemTags.add(toBeginningOfSentenceCase(tag));
        });
      }
    });
    menuItemTags = menuItemTags.toSet().toList();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: appBar,
        body: Container(
          color: Color(0xFFF9F9F6),
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          menuItemTags.length + 1,
                          (index) => index == 0
                              ? ChoiceChip(
                                  label: Text(
                                    "All",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: selectedTag == ""
                                          ? Color(0xFFFFC700)
                                          : Color(0xFF878787),
                                    ),
                                  ),
                                  selected: selectedTag == "",
                                  onSelected: (_) {
                                    if (selectedTag != "") {
                                      setState(() {
                                        selectedTag = "";
                                      });
                                    }
                                  },
                                )
                              : Row(
                                  children: [
                                    VTDivider(width: 8),
                                    ChoiceChip(
                                      label: Text(
                                        menuItemTags[index - 1],
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: selectedTag ==
                                                  menuItemTags[index - 1]
                                              ? Color(0xFFFFC700)
                                              : Color(0xFF878787),
                                        ),
                                      ),
                                      selected: selectedTag ==
                                          menuItemTags[index - 1],
                                      onSelected: (_) {
                                        if (selectedTag !=
                                            menuItemTags[index - 1]) {
                                          setState(() {
                                            selectedTag =
                                                menuItemTags[index - 1];
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  TDivider(),
                  Expanded(
                    child: GridView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      // physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.63,
                      ),
                      children: shopItems,
                    ),
                  ),
                  TDivider(),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: CartButton(
                  onTap: openOrderSummaryPage,
                  quantity: cartQuantity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
