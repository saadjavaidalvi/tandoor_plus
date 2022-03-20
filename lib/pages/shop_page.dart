import 'package:flutter/material.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/image_loader.dart';
import 'package:user/common/shared.dart';
import 'package:user/common/spinning_logo.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/shop.dart';
import 'package:user/models/shop_menu_item.dart';
import 'package:user/pages/shop_menu_view_page.dart';

DatabaseManager _databaseManager;

class ShopPage extends StatefulWidget {
  static final String route = "shop";

  final String id;
  final Shop shop;

  ShopPage({
    this.id,
    this.shop,
  }) {
    _databaseManager = DatabaseManager.instance;
  }

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Shop shop;
  bool progressBarVisible;

  Map<String, List<ShopMenuItem>> categoryMenuItems;

  @override
  void initState() {
    super.initState();
    progressBarVisible = true;

    if (widget.shop != null)
      shop = widget.shop;
    else
      throw UnimplementedError("Method unimplemented");

    loadMenuItems();
  }

  static Map<String, List<ShopMenuItem>> _sortMenuItemsInCategories(
      List<ShopMenuItem> menuItems) {
    Map<String, List<ShopMenuItem>> map = {};

    menuItems.forEach((menuItem) {
      String category = menuItem.category ?? 'General';
      map[category] = map[category] ?? List<ShopMenuItem>.empty(growable: true);
      map[category].add(menuItem);
    });

    return map;
  }

  void loadMenuItems() async {
    // Reset state variables before calling this method
    if (shop?.id != null) {
      Map<String, List<ShopMenuItem>> categoryMenuItems =
          this.categoryMenuItems ??
              _sortMenuItemsInCategories(
                await _databaseManager.getMenuItems(
                  shop.id,
                ),
              );

      while (!mounted) await Future.delayed(Duration(milliseconds: 200));

      if (categoryMenuItems.isNotEmpty) {
        setState(() {
          this.categoryMenuItems = categoryMenuItems;
          progressBarVisible = false;
        });
      }
    }

    if (progressBarVisible) {
      setState(() {
        progressBarVisible = false;
      });
    }
  }

  void openMenuViewPage(category) {
    Navigator.of(context).pushNamed(
      ShopMenuViewPage.route,
      arguments: [
        shop,
        category,
        categoryMenuItems[category],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = getAppBar(
      context,
      AppBarType.backWithWidget,
      backgroundColor: Colors.white,
      iconsColor: Colors.white,
      leadingWidget: Row(
        children: [
          Icon(
            Icons.share,
            color: Colors.white,
          ),
          VerticalDivider(
            color: Colors.black,
          ),
          Icon(
            Icons.info_outline,
            color: Colors.white,
          ),
        ],
      ),
      onBackPressed: () => Navigator.pop(context),
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('TMart',style: TextStyle(fontWeight: FontWeight.w600),),
          backgroundColor: Colors.white,
        ),
        body: Container(
          color: Color(0xFFF9F9F6),
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stack(
                    //   children: [
                    //     // ImageLoader(
                    //     //   imageUrl: shop?.imageUrl,
                    //     //   fit: BoxFit.cover,
                    //     //   height: 300,
                    //     //   width: double.infinity,
                    //     //   available: shop?.available,
                    //     // ),
                    //     // Container(
                    //     //   width: MediaQuery.of(context).size.width,
                    //     //   height: 300,
                    //     //   color: Colors.black.withOpacity(0.3),
                    //     // ),
                    //     Positioned(
                    //       bottom: 0,
                    //       child: Container(
                    //         width: MediaQuery.of(context).size.width,
                    //         padding: const EdgeInsets.symmetric(
                    //           horizontal: 16,
                    //           vertical: 8,
                    //         ),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               shop?.nameEnglish ?? "",
                    //               style: AppTextStyle.copyWith(
                    //                 fontSize: 28,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Colors.white,
                    //               ),
                    //             ),
                    //             Text(
                    //               shop?.nameUrdu ?? "",
                    //               style: AppTextStyle.copyWith(
                    //                 fontSize: 20,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Colors.white.withOpacity(0.8),
                    //               ),
                    //             ),
                    //             Row(
                    //               children: [
                    //                 Visibility(
                    //                   visible: shop?.distanceTime != null,
                    //                   child: Container(
                    //                     decoration: BoxDecoration(
                    //                       border: Border.all(
                    //                         color: appPrimaryColor,
                    //                         width: 0.5,
                    //                       ),
                    //                       borderRadius:
                    //                           BorderRadius.circular(7),
                    //                     ),
                    //                     padding: const EdgeInsets.all(8),
                    //                     child: Text(
                    //                       "Delivery ${shop?.distanceTimeString}",
                    //                       style: AppTextStyle.copyWith(
                    //                         color: appPrimaryColor,
                    //                         fontWeight: FontWeight.bold,
                    //                       ),
                    //                     ),
                    //                   ),
                    //                 ),
                    //                 VerticalDivider(color: Colors.transparent),
                    //                 Visibility(
                    //                   visible: shop.deliveryPrice != null &&
                    //                       shop.deliveryPrice > 0,
                    //                   child: Container(
                    //                     decoration: BoxDecoration(
                    //                       border: Border.all(
                    //                         color: appPrimaryColor,
                    //                         width: 0.5,
                    //                       ),
                    //                       borderRadius:
                    //                           BorderRadius.circular(7),
                    //                     ),
                    //                     padding: const EdgeInsets.all(8),
                    //                     child: Text(
                    //                       "Charges Rs. ${shop?.deliveryPrice?.toStringAsFixed(0)}",
                    //                       style: AppTextStyle.copyWith(
                    //                         color: appPrimaryColor,
                    //                         fontWeight: FontWeight.bold,
                    //                       ),
                    //                     ),
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //             Divider(
                    //               color: Colors.transparent,
                    //               height: 8,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 18,
                      ),
                      child: Text(
                        "Ab sb saman ungli k isharay par!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                    fontSize: getARFontSize(context, NormalSize.S_22),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: progressBarVisible,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinningLogo(
                            name: "assets/launcher/foreground.png",
                            height: 100,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          categoryMenuItems?.keys?.length ?? 0,
                          // 4,
                          (index) {
                            String category =
                                categoryMenuItems.keys.elementAt(index);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 21,
                                vertical: 14,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      // offset: Offset(0, -2),
                      blurRadius: 2,
                    ),
                  ],
                              ),
                              child: InkWell(
                                onTap: () => openMenuViewPage(
                                  category,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Expanded(child: Container()),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.black12,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.transparent,
                      height: 25,
                    ),
                    Divider(
                      indent: 124,
                      endIndent: 124,
                      thickness: 2,
                    ),
                    Divider(
                      color: Colors.transparent,
                      height: 75,
                    ),
                  ],
                ),
              ),
              // Positioned(
              //   top: 0,
              //   left: 0,
              //   right: 0,
              //   child: appBar,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
