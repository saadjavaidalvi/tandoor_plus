import 'dart:async';

import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/cart_button.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/draggable_list_view.dart';
import 'package:user/common/image_loader.dart';
import 'package:user/common/marquee_widget.dart';
import 'package:user/common/product_card_widget.dart';
import 'package:user/common/shared.dart';
import 'package:user/common/spinning_logo.dart';
import 'package:user/common/tandoor_menu.dart';
import 'package:user/common/tile_text.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/address.dart';
import 'package:user/models/cart.dart';
import 'package:user/models/contact_info.dart';
import 'package:user/models/db_entities.dart';
import 'package:user/models/order.dart';
import 'package:user/models/order_item.dart';
import 'package:user/models/shop.dart';
import 'package:user/models/wallet.dart';
import 'package:user/pages/address_page.dart';
import 'package:user/pages/buy_something_page.dart';
import 'package:user/pages/contact_info_page.dart';
import 'package:user/pages/order_summary_page.dart';
import 'package:user/pages/profile_page.dart';
import 'package:user/pages/send_something_page.dart';
import 'package:user/pages/shop_page.dart';
import 'package:user/pages/transations_page.dart';
import 'package:user/provider/cart_quantity_provider.dart';


import 'your_orders_page.dart';

ScrollController _scrollController;
DatabaseManager _databaseManager;
TextEditingController _searchController;

class HomePage extends StatefulWidget {
  static final String route = "home";

  HomePage() {
    _scrollController = ScrollController();
    _databaseManager = DatabaseManager.instance;
    _searchController = TextEditingController();
  }

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  _TABS selectedTab;
  int points;
  double wallet;
  int cartQuantity;
  bool progressBarVisible;
  List<Shop> nearByShops;
  List<Shop> nearByShopsSearchResults;
  bool isOffline;
  bool shopsProgressBarVisible;
  Cart cart;

  PageController pageController;

  // For address
  bool draggableListVisible;
  int selectedAddressIndex;
  List<AddressEntity> _addressEntities = [];

  List<ProductCardWidget> productItems;

  bool locationAvailable;

  // ignore: cancel_subscriptions
  StreamSubscription streamSubscription;

  bool searchResultsVisible;

  _HomePage() {
    cart = getIt.get<Cart>();
  }

  Shop tMartShop = Shop(
                              address:"Allama Iqbal Town, Lahore",
                              available:true,
                              deliveryPrice:null,
                              distance:556.0,
                              distanceTime:18,
                              id:"8rzazhUgDnfGvll1yazTQTZofE52",
                              imageUrl:"https://i.imgur.com/euiUQZ6.jpg",
                              nameEnglish:"TMart",
                              nameUrdu:null,);

  @override
  void initState() {
    super.initState();
    selectedTab = _TABS.ROTI;
    points = 0;
    wallet = 0;
    cartQuantity = 0;
    context.read<CartProvider>().updateCartQuantity(cartQuantity);
    progressBarVisible = true;
    isOffline = false;
    shopsProgressBarVisible = true;
    searchResultsVisible = false;

    pageController = PageController();
    loadConfig();

    draggableListVisible = false;
    selectedAddressIndex = -1;
    _addressEntities = [];
    productItems = [];

    locationAvailable = false;

    DatabaseManager.instance.getAddresses().then((addressEntities) {
      _addressEntities = addressEntities;
      if (_addressEntities.length > 0)
        setState(() {
          selectedAddressIndex = 0;
        });
    });

    loadNearYouShops();

    String uid = FirebaseAuth.instance.currentUser.uid;
    streamSubscription =
        _databaseManager.walletRef.child(uid).onValue.listen((event) {
      updateWallet((event.snapshot?.value ?? 0) * 1.0);
    });
  }

  void searchShop() {
    String searchText = _searchController.text.trim().toLowerCase();
    if (searchText.length == 0) {
      setState(() {
        this.nearByShopsSearchResults = [];
        searchResultsVisible = false;
      });
    } else if (nearByShops != null) {
      List<Shop> nearByShopsSearchResults = nearByShops.where((element) {
        return (element.nameEnglish ?? "").toLowerCase().indexOf(searchText) >=
                0 ||
            (element.nameUrdu ?? "").toLowerCase().indexOf(searchText) >= 0;
      }).toList();
      setState(() {
        this.nearByShopsSearchResults = nearByShopsSearchResults;
        searchResultsVisible = true;
      });
    }
  }

  void updateWallet(double amount) {
    printInfo("Update wallet to: $amount");
    getIt.get<Wallet>().amount = amount;

    if (mounted) {
      setState(() {
        wallet = amount;
      });
    } else {
      wallet = amount;
    }
  }

  void loadNearYouShops() async {
    if (!progressBarVisible)
      setState(() {
        progressBarVisible = true;
      });

    if (await getLocationPermission()) {
      setState(() {
        locationAvailable = true;
      });
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (position != null) {
        List<Shop> nearByShops = await _databaseManager.getShopsNear(
          context,
          position,
        );

        setState(() {
          this.nearByShops = nearByShops;
          shopsProgressBarVisible = false;
        });
      }
    }
    if (shopsProgressBarVisible)
      setState(() {
        shopsProgressBarVisible = false;
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    try {
      streamSubscription?.cancel?.call();
    } catch (e) {
      printInfo("Error in streamSubscription.cancel: $e");
    }
    super.dispose();
  }

  void openShop(Shop shop) async {
    await Navigator.of(context).pushNamed(
      ShopPage.route,
      arguments: shop,
    );

    setState(() {
      cart = getIt.get<Cart>();
      cart.subCarts.forEach((sc) {
        sc.orderItems.removeWhere(
          (element) => element.quantity <= 0 || element.price <= 0,
        );
      });
      cartQuantity = cart.cartQuantity;
      context.read<CartProvider>().updateCartQuantity(cartQuantity);
      initCards();
    });
  }

  void initCards() {
    List<ProductCardWidget> _items = [];

    for (String id in TandoorMenu.productIDs) {
      double rate = TandoorMenu.getRateById(id);
      if (rate > 0) {
        _items.add(
          ProductCardWidget(
            id,
            TandoorMenu.getNameById(id),
            TandoorMenu.getUrduNameById(id),
            TandoorMenu.getImageById(id),
            TandoorMenu.getRateById(id),
            cart.subCarts.length == 1
                ? cart.subCarts[0].orderItems
                        .firstWhere((element) => element.id == id,
                            orElse: () => null)
                        ?.quantity ??
                    0
                : 0,
            quantityChanged,
            false,
          ),
        );
      }
    }
    if (_items.length > 0)
      setState(() {
        productItems.clear();
        productItems = _items;
      });
  }

  void loadConfig() async {
    if (mounted) {
      setState(() {
        progressBarVisible = true;
      });
    }

    try {
      await TandoorMenu.loadTandoorAppConfig();
    } catch (e) {
      printInfo("Error: $e");
      WidgetsFlutterBinding.ensureInitialized();
      showOkMessage(
        context,
        "Failed",
        "Failed to load items. Please check your internet connection.",
      );
      setState(() {
        progressBarVisible = false;
      });
      return;
    }

    while (!mounted) await Future.delayed(Duration(milliseconds: 200));

    initCards();
    setState(() {
      isOffline = !isInActiveHours(getEpochOfDevice());
      // isOffline = false;

      progressBarVisible = false;

      if (isOffline) cart?.clear();
    });

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      int buildNumber = int.tryParse(packageInfo?.buildNumber ?? "0") ?? 0;
      int compBuildNumber = TandoorMenu.tandoorAppConfig["build_number"] ?? 0;
      if (compBuildNumber > buildNumber) {
        showUpdateMessage(context);
      }
    });
  }

  void onHeaderClicked(_TABS tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  void replaceCartOfOtherShop(
    String itemId,
    int quantity,
    Function performChange,
  ) {
    cart.clear();
    cart.subCarts.add(SubCart());
    quantityChanged(itemId, quantity, performChange);
  }

  void quantityChanged(String itemId, int quantity, Function performChange) {
    
    if (!cart.isGeneral) {
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
    } else {
      int i = cart.subCarts[0].orderItems
          .indexWhere((element) => element.id == itemId);

      setState(() {
        if (i < 0) {
          cart.subCarts[0].orderItems.add(
            OrderItem(
              id: itemId,
              quantity: quantity,
              price: TandoorMenu.getRateById(itemId),
              name: TandoorMenu.getNameById(itemId),
              urduName: TandoorMenu.getUrduNameById(itemId),
            ),
          );
        } else {
          cart.subCarts[0].orderItems[i].quantity = quantity;
        }

        cart.subCarts[0].orderItems.removeWhere(
              (element) => element.quantity <= 0 || element.price <= 0,
        );

        cartQuantity = cart.cartQuantity;
        // context.read<CartProvider>().updateCartQuantity(cartQuantity);
        context.read<CartProvider>().updateCartQuantity(cartQuantity);
        
      
      });
      performChange();
    }
  }


  void resetOrder() {
    setState(() {
      selectedTab = _TABS.ROTI;
      points = 0;
      cartQuantity = 0;
      context.read<CartProvider>().updateCartQuantity(cartQuantity);
      progressBarVisible = true;
      cart.clear();
    });

    pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeIn,
    );
    loadConfig();
  }

  void openOrderSummaryPage() async {
    if (cartQuantity > 0) {
      // Open Add address if no address has been added before
      bool askContact = false;
      if (cart.address == null) {
        AddressEntity addressEntity = await addNewAddress();
        if (addressEntity != null) {
          askContact = true;
          cart.address = Address.fromAddressEnt(addressEntity);
        }
      }

      if (askContact && cart.contactInfo == null) {
        ContactInfoEntity contactInfoEntity = await addNewContactInfo();
        if (contactInfoEntity != null)
          cart.contactInfo =
              ContactInfo.fromContactInfoEntity(contactInfoEntity);
      }

      await Navigator.pushNamed(context, OrderSummaryPage.route);

      setState(() {
        cart = getIt.get<Cart>();
        if (cart.subCarts.length > 0) {
          cart.subCarts[0].orderItems.removeWhere(
                (element) => element.quantity <= 0 || element.price <= 0,
          );
        } else {
          cart.subCarts.add(SubCart());
        }
        cartQuantity = cart.cartQuantity;
        context.read<CartProvider>().updateCartQuantity(cartQuantity);
      });

      loadConfig();
    }
  }

  void hideAddressList() {
    setState(() {
      draggableListVisible = false;
    });
  }

  void setAddress(int i) {
    hideAddressList();
    if (i >= 0) {
      setState(() {
        selectedAddressIndex = i;
      });
    }
  }

  Future<AddressEntity> addNewAddress() async {
    hideAddressList();
    await Get.delete(tag: MartOrderTag);
    AddressEntity newAddressEntity = await Navigator.pushNamed(
      context,
      AddressPage.route,
      arguments: ContactInfoType.TANDOOR_DROP_OFF,
    ) as AddressEntity;
    if (newAddressEntity != null) {
      printInfo(
          "HomePage got new address with city ${newAddressEntity.city} at id ${newAddressEntity.id}");
      _addressEntities.add(newAddressEntity);
      setAddress(_addressEntities.length - 1);
    }
    return newAddressEntity;
  }

  Future<ContactInfoEntity> addNewContactInfo() async {
    await Get.delete(tag: MartOrderTag);
    ContactInfoEntity newContactInfoEntity = await Navigator.pushNamed(
      context,
      ContactInfoPage.route,
      arguments: [ContactInfoType.TANDOOR_DROP_OFF],
    ) as ContactInfoEntity;
    if (newContactInfoEntity != null) {
      printInfo(
        "HomePage got new contact info with name ${newContactInfoEntity.name} and id ${newContactInfoEntity.id}",
      );
    }
    return newContactInfoEntity;
  }

  @override
  Widget build(BuildContext context) {
    
    _HeaderIconText rotiHeader = _HeaderIconText(
      UniqueKey(),
      "assets/icons/ic_header_roti.png",
      "Roti",
      selectedTab == _TABS.ROTI,
          () {
        pageController.animateToPage(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      },
    );
    _HeaderIconText shopsHeader = _HeaderIconText(
      UniqueKey(),
      "assets/icons/ic_header_shops.png",
      "Shops",
      selectedTab == _TABS.SHOPS,
      () {
        pageController.animateToPage(
          1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      },
    );
    _HeaderIconText deliveryHeader = _HeaderIconText(
      UniqueKey(),
      "assets/icons/ic_order_timeline_3.png",
      "Mart",
      selectedTab == _TABS.DELIVERY,
      () {
        pageController.animateToPage(
          2,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      },
    );

    List<ListTileTemplate> addresses = [
      TitleListTile(
        "Select delivery address",
        onBack: hideAddressList,
      ),
      SelectionListTitle(
        "Add New Destination",
        onTap: addNewAddress,
        fontColor: appPrimaryColor,
        leadingIcon: Icons.add,
      ),
      ...List.generate(
        _addressEntities.length,
            (index) => SelectionListTitle(
          _addressEntities[index].toTitle(),
          leadingImage: "assets/icons/ic_address2.png",
          onTap: () {
            setAddress(index);
          },
        ),
      ),
    ];

    if (selectedAddressIndex >= 0) {
      cart.address = Address.fromAddressEnt(
        _addressEntities[selectedAddressIndex],
      );
    }

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop(animated: true);
        return false;
      },
      child: Scaffold(
         backgroundColor: Color(0xffF9FAF5),
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0.0,
          leading: Container(),
          titleSpacing: 0,
          title: Transform(
            transform: Matrix4.translationValues(-30, 0, 0),
            child: Image.asset(
              "assets/images/tandoor_plus_logo.png",
              width: 110,
            ),
          ),
          shadowColor: Colors.transparent,
          actions: [
            Visibility(
              visible: false,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/icons/ic_present.png",
                          width: 18,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            "$points points",
                            style: TextStyle(
                              fontSize: getARFontSize(context, NormalSize.S_16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFFD2D2D2),
                          size: 13,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                Navigator.of(context).pushNamed(TransactionsPage.route);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/icons/ic_cod.png",
                          width: 18,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            "Rs. ${wallet.toInt()}",
                            style: TextStyle(
                              fontSize: getARFontSize(context, NormalSize.S_16),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFFD2D2D2),
                          size: 13,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: DoubleBackToCloseApp(
          snackBar: const SnackBar(
            content: Text('Press back again to leave'),
          ),
          child: Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      expandedHeight: MediaQuery.of(context).size.width * 0.2,
                      leading: Container(),
                      pinned: false,
                      backgroundColor: backgroundColor,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          color: backgroundColor,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text("Hi, ${getGreetings()}!",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: getARFontSize(
                                            context, NormalSize.S_22),
                                      )),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Container(
                                    height:
                                        getARFontSize(context, NormalSize.S_18),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Deliver to:  ",
                                          style: TextStyle(
                                            fontSize: getARFontSize(
                                                context, NormalSize.S_16),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _addressEntities.length > 0
                                              ? () {
                                                  setState(() {
                                                    draggableListVisible = true;
                                                  });
                                                }
                                              : addNewAddress,
                                          style: ButtonStyle(
                                              padding:
                                                  MaterialStateProperty.all(
                                                      EdgeInsets.zero)),
                                          child: Row(
                                            children: [
                                              Text(
                                                _addressEntities.length > 0
                                                    ? _addressEntities[
                                                            selectedAddressIndex]
                                                        .toTitle()
                                                    : "Add address",
                                                style: TextStyle(
                                                  fontSize: getARFontSize(
                                                      context, NormalSize.S_16),
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_outlined,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                size: getARFontSize(
                                                    context, NormalSize.S_22),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: backgroundColor,
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: _verticalContainer('Tandoor',
                            Image.asset('assets/icons/tandoor.png',fit: BoxFit.contain,),_RotiPage(productItems,isOffline,openOrderSummaryPage),margins:EdgeInsets.only(left: 20,right: 10,top: 10))),
                            Expanded(child: _verticalContainer('TMart',Image.asset('assets/icons/tmart.png',fit: BoxFit.contain,),
                            ShopPage(shop: tMartShop)
                                ,margins:EdgeInsets.only(left: 10,right: 20,top: 10))),
                          ],),
                          _horizontalContainer('Package\n& more',Image.asset('assets/icons/package_more.png',fit: BoxFit.contain,),_MartPage(
                                  isOffline,
                                ),),
                          // IntrinsicHeight(
                          //   child: Container(
                          //     width: double.infinity,
                          //     decoration: BoxDecoration(
                          //       color: Colors.white,
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     margin:
                          //         const EdgeInsets.symmetric(horizontal: 24),
                          //     child: Row(
                          //       mainAxisAlignment:
                          //           MainAxisAlignment.spaceBetween,
                          //       mainAxisSize: MainAxisSize.max,
                          //       children: [
                          //         rotiHeader,
                          //         shopsHeader,
                          //         deliveryHeader,
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // Expanded(
                          //   child: PageView(
                          //     controller: pageController,
                          //     clipBehavior: Clip.none,
                          //     onPageChanged: (int position) {
                          //       _TABS tab = _TABS.values[position];
                          //       if (selectedTab != tab) onHeaderClicked(tab);
                          //     },
                          //     children: [
                          //       _RotiPage(productItems, isOffline),
                          //       _ShopsPage(
                          //         isOffline,
                          //         locationAvailable,
                          //         shopsProgressBarVisible,
                          //         searchResultsVisible,
                          //         List.generate(
                          //           (searchResultsVisible
                          //                       ? nearByShopsSearchResults
                          //                       : nearByShops)
                          //                   ?.length ??
                          //               0,
                          //           (index) => _ShopItem(
                          //             (searchResultsVisible
                          //                 ? nearByShopsSearchResults
                          //                 : nearByShops)[index],
                          //             openShop,
                          //           ),
                          //         ),
                          //         loadNearYouShops,
                          //         searchShop,
                          //       ),
                          //       _MartPage(
                          //         isOffline,
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      width: MediaQuery.of(context).size.width,
                      child: Container(
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.25),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            FooterMenu(
                              true,
                              "assets/icons/ic_menu_home.png",
                              "Home",
                              () {
                                _scrollController.animateTo(
                                  0,
                                  duration: Duration(milliseconds: 100),
                                  curve: Curves.linear,
                                );
                              },
                            ),
                            FooterMenu(
                                false,
                                "assets/icons/ic_menu_my_orders.png",
                                "My Orders", () {
                              Navigator.pushNamed(
                                context,
                                YourOrdersPage.route,
                              );
                            }),
                            Divider(
                              thickness: 0,
                              height: 0,
                              indent: 10,
                            ),
                            FooterMenu(
                                false,
                                "assets/icons/ic_menu_foodbook.png",
                                "Foodbook", () {
                              // Todo: Open Foodbook page
                            }),
                            FooterMenu(
                              false,
                              "assets/icons/ic_menu_profile.png",
                              "Profile",
                                  () {
                                Navigator.pushNamed(context, ProfilePage.route);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      width: 64,
                      height: 64,
                      child: CartButton(
                        onTap: openOrderSummaryPage,
                        quantity: context.watch<CartProvider>().quantity,
                        // cartQuantity,
                      ),
                    ),
                  ],
                ),
              ),
              DraggableListView(
                visible: draggableListVisible,
                children: addresses,
                onHide: hideAddressList,
              ),
              AppProgressBar(visible: progressBarVisible),
            ],
          ),
        ),
      ),
    );
  }

  Widget _horizontalContainer(String title,Widget icon,Widget className){
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (route)=>className));
      },
      child: Container(
        margin: EdgeInsets.only(left: 20,right: 20,top: 20,bottom: 46,),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              // spreadRadius: 2,
              blurRadius: 5
            )
          ],
        color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:10.0),
          child: Row(children: [
            Expanded(
              child: Text(title,style: TextStyle(
                fontSize: getARFontSize(context,NormalSize.S_48),
                fontWeight: FontWeight.w600,
                height: 1,
              ),textAlign: TextAlign.center,),
            ),
            Container(width: 30,),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(vertical:10.0),
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffF9F9F7),
                ),
                child: Center(child: Container(height: 100,child: icon)),
              ),
            ),
          ],),
        ),
      ),
    );
  }

  Widget _verticalContainer(String title,Widget icon,Widget className,{EdgeInsets margins}){
    return GestureDetector(
      onTap: ()async{
        await Navigator.push(context, MaterialPageRoute(builder: (route)=>className));
        // setState(() {
          // quantityChanged(itemId, quantity, performChange)
        // });
      },
      child: Container(
        margin:margins ??  EdgeInsets.only(left: 20,right: 20,top: 00,bottom: 0,),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              // spreadRadius: 2,
              blurRadius: 5
            )
          ],
        color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:10.0,vertical: 10),
          child: Column(children: [
            Container(
              margin: EdgeInsets.symmetric(vertical:10.0),
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xffF9F9F7),
              ),
              child: Center(child: Container(
                height: 100,
                child: icon,),),
            ),
            Text(title,style: TextStyle(
              fontSize: getARFontSize(context,NormalSize.S_48),
              fontWeight: FontWeight.w600,
              height: 1,
            ),textAlign: TextAlign.center,),
            Container(height: 20,),
          ],),
        ),
      ),
    );
  }
}

class _RotiPage extends StatefulWidget {
  final List<ProductCardWidget> productItems;
  final bool isOffline;
  final Function openOrderSummaryPage;

  _RotiPage(this.productItems,this.isOffline,this.openOrderSummaryPage);

  @override
  State<_RotiPage> createState() => _RotiPageState();
}

class _RotiPageState extends State<_RotiPage> {

  // Cart cart;

  // int cartQuantity;

  // // PageController pageController;

  // // // For address
  // // bool draggableListVisible;
  // // int selectedAddressIndex;
  // // List<AddressEntity> _addressEntities = [];

  // List<ProductCardWidget> productItems;


  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();

  //   productItems = [];

  //   cart = getIt.get<Cart>();
  //     cart.subCarts.forEach((sc) {
  //       sc.orderItems.removeWhere(
  //         (element) => element.quantity <= 0 || element.price <= 0,
  //       );
  //     });
  //     cartQuantity = cart.cartQuantity;
  // context.read<CartProvider>().updateCartQuantity(cartQuantity);
  //     initCards();
  // }

  // void initCards() {
  //   List<ProductCardWidget> _items = [];

  //   for (String id in TandoorMenu.productIDs) {
  //     double rate = TandoorMenu.getRateById(id);
  //     if (rate > 0) {
  //       _items.add(
  //         ProductCardWidget(
  //           id,
  //           TandoorMenu.getNameById(id),
  //           TandoorMenu.getUrduNameById(id),
  //           TandoorMenu.getImageById(id),
  //           TandoorMenu.getRateById(id),
  //           cart.subCarts.length == 1
  //               ? cart.subCarts[0].orderItems
  //                       .firstWhere((element) => element.id == id,
  //                           orElse: () => null)
  //                       ?.quantity ??
  //                   0
  //               : 0,
  //           quantityChanged,
  //           false,
  //         ),
  //       );
  //     }
  //   }
  //   if (_items.length > 0)
  //     setState(() {
  //       productItems.clear();
  //       productItems = _items;
  //     });
  // }


  // void quantityChanged(String itemId, int quantity, Function performChange) {
  //   if (!cart.isGeneral) {
  //     if (cart.cartQuantity > 0) {
  //       showShopChangeConfirmation(
  //         context,
  //         "You already have items in your cart from another shop. Do you want to remove all other items and add this?",
  //         onYes: () {
  //           replaceCartOfOtherShop(itemId, quantity, performChange);
  //         },
  //       );
  //     } else {
  //       replaceCartOfOtherShop(itemId, quantity, performChange);
  //     }
  //   } else {
  //     int i = cart.subCarts[0].orderItems
  //         .indexWhere((element) => element.id == itemId);

  //     setState(() {
  //       if (i < 0) {
  //         cart.subCarts[0].orderItems.add(
  //           OrderItem(
  //             id: itemId,
  //             quantity: quantity,
  //             price: TandoorMenu.getRateById(itemId),
  //             name: TandoorMenu.getNameById(itemId),
  //             urduName: TandoorMenu.getUrduNameById(itemId),
  //           ),
  //         );
  //       } else {
  //         cart.subCarts[0].orderItems[i].quantity = quantity;
  //       }

  //       cart.subCarts[0].orderItems.removeWhere(
  //             (element) => element.quantity <= 0 || element.price <= 0,
  //       );

  //       cartQuantity = cart.cartQuantity;
  // context.read<CartProvider>().updateCartQuantity(cartQuantity);
  //     });

  //     performChange();
  //   }
  // }

  // void replaceCartOfOtherShop(
  //   String itemId,
  //   int quantity,
  //   Function performChange,
  // ) {
  //   cart.clear();
  //   cart.subCarts.add(SubCart());
  //   quantityChanged(itemId, quantity, performChange);
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void quantityChanged(String itemId, int quantity, Function performChange) {}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CartButton(
        onTap: widget.openOrderSummaryPage,
        quantity: context.watch<CartProvider>().quantity,
        // getIt.get<Cart>().cartQuantity,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: Text('Tandoor',style: TextStyle(
          fontWeight: FontWeight.w600,
        ),),
        backgroundColor: Colors.white,
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 8.0,
                left: 24,
                right: 24,
              ),
              child: Visibility(
                visible: !widget.isOffline,
                child: Text(
                  "Jee janab, kitni rotiyan?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: getARFontSize(context, NormalSize.S_22),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Visibility(
                    visible: !widget.isOffline,
                    child: GridView(
                      padding: 
                      const EdgeInsets.only(left: 24.0,right:24,bottom: 100),
                      // physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.73,
                      ),
                      children: widget.productItems,
                    ),
                  ),
                  Visibility(
                    visible: widget.isOffline,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              "assets/images/closed.png",
                            ),
                            Text(
                              "Sorry we are offline",
                              style: AppTextStyle.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              "TandoorPlus active hours are: ${TandoorMenu.tandoorAppConfig["active_hours"].toString().replaceAll("-", " - ")}",
                              style: AppTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider(
            //   thickness: 0,
            //   height: 65.0,
            //   color: Colors.transparent,
            // ),
          ],
        ),
      ),
    );
  }
}

class _ShopsPage extends StatelessWidget {
  final bool isOffline;
  final bool locationAvailable;
  final bool progressBarVisible;
  final bool searchResultsVisible;
  final List<Widget> children;
  final void Function() getLocationPermission;
  final void Function() onSearchSubmit;

  _ShopsPage(
    this.isOffline,
    this.locationAvailable,
    this.progressBarVisible,
    this.searchResultsVisible,
    this.children,
    this.getLocationPermission,
    this.onSearchSubmit,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TMart',style: TextStyle(
          fontWeight: FontWeight.w600,
        ),),
        backgroundColor: Colors.white,
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 8.0,
                left: 24,
                right: 24,
              ),
              child: Visibility(
                visible: !isOffline,
                child: Text(
                  "Ab sb saman ungli k isharay par!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: getARFontSize(
                      context,
                      NormalSize.S_22,
                    ),
                  ),
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
            //   child: Theme(
            //     data: ThemeData(
            //       fontFamily: GoogleFonts.nunitoSans().fontFamily,
            //       primaryColor: Colors.black,
            //       primarySwatch: MaterialColor(
            //         Colors.black45.value,
            //         <int, Color>{
            //           50: Colors.black45,
            //           100: Colors.black45,
            //           200: Colors.black45,
            //           300: Colors.black45,
            //           400: Colors.black45,
            //           500: Colors.black45,
            //           600: Colors.black45,
            //           700: Colors.black45,
            //           800: Colors.black45,
            //           900: Colors.black45,
            //         },
            //       ),
            //     ),
            //     child: TextField(
            //       controller: _searchController,
            //       autofocus: false,
            //       decoration: InputDecoration(
            //         border: OutlineInputBorder(
            //           gapPadding: 0,
            //           borderSide: BorderSide(color: Colors.black),
            //         ),
            //         hintText: "Search Shop",
            //         contentPadding: EdgeInsets.symmetric(horizontal: 8),
            //       ),
            //       keyboardType: TextInputType.text,
            //       maxLines: 1,
            //       onSubmitted: (_) => onSearchSubmit(),
            //       textInputAction: TextInputAction.search,
            //       onChanged: (value) {
            //         if (value.length == 0) {
            //           onSearchSubmit();
            //         }
            //       },
            //     ),
            //   ),
            // ),
            Expanded(
              child: Stack(
                children: [
                  Visibility(
                    visible: locationAvailable &&
                        !isOffline &&
                        (progressBarVisible || children.length > 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ListView(
                        key: UniqueKey(),
                        children: [
                          ...this.children,
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
                          Divider(
                            indent: 124,
                            endIndent: 124,
                            thickness: 2,
                          ),
                          Divider(
                            color: Colors.transparent,
                            height: 35,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isOffline,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              "assets/images/closed.png",
                            ),
                            Text(
                              "Sorry we are offline",
                              style: AppTextStyle.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              "TandoorPlus active hours are: ${TandoorMenu.tandoorAppConfig["active_hours"].toString().replaceAll("-", " - ")}",
                              style: AppTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !locationAvailable && !isOffline,
                    child: GestureDetector(
                      onTap: () {
                        getLocationPermission();
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                "assets/images/closed.png",
                              ),
                              Text(
                                "Location permission required",
                                style: AppTextStyle.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                "We need your location to find shops near you.",
                                style: AppTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  !locationAvailable && !isOffline ? Container() :
                  Visibility(
                    visible: children.length == 0 &&
                        !progressBarVisible &&
                        !searchResultsVisible,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              "assets/images/closed.png",
                            ),
                            Text(
                              "No shop is available near you",
                              style: AppTextStyle.copyWith(
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              thickness: 0,
              height: 65.0,
              color: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _MartPage extends StatelessWidget {
  final bool isOffline;

  _MartPage(this.isOffline);

  void openSendSomethingPage(BuildContext context) async {
    Order order = Order(
      type: ORDER_TYPE.PARCEL.index,
      deliveryPrice: double.parse(
        "${TandoorMenu.tandoorAppConfig["delivery_charges"]}",
      ),
    );
    await Get.delete<Order>(tag: MartOrderTag);
    Get.put<Order>(order, tag: MartOrderTag);
    Navigator.of(context).pushNamed(
      SendSomethingPage.route,
      arguments: true,
    );
  }

  void openReceiveSomethingPage(BuildContext context) async {
    Order order = Order(
      type: ORDER_TYPE.PARCEL.index,
      deliveryPrice: double.parse(
        "${TandoorMenu.tandoorAppConfig["delivery_charges"]}",
      ),
    );
    await Get.delete<Order>(tag: MartOrderTag);
    Get.put<Order>(order, tag: MartOrderTag);
    Navigator.of(context).pushNamed(
      SendSomethingPage.route,
      arguments: true,
    );
  }

  void openBuySomethingPage(BuildContext context) async {
    Order order = Order(
      type: ORDER_TYPE.SHOPPING.index,
      deliveryPrice: double.parse(
        "${TandoorMenu.tandoorAppConfig["delivery_charges"]}",
      ),
    );
    await Get.delete<Order>(tag: MartOrderTag);
    Get.put<Order>(order, tag: MartOrderTag);
    Navigator.of(context).pushNamed(BuySomethingPage.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Package & more',style: TextStyle(
          fontWeight: FontWeight.w600,
        ),),
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 8.0,
                left: 24,
                right: 24,
              ),
              child: Visibility(
                visible: !isOffline,
                child: Text(
                  "What would you like to do?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: getARFontSize(
                      context,
                      NormalSize.S_22,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Visibility(
                    visible: !isOffline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          TDivider(),
                          InkWell(
                            onTap: () => openSendSomethingPage(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: Color(0xFFEFEFEF),
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: backgroundColor,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    width: 60,
                                    height: 60,
                                    child: Image.asset(
                                      "assets/icons/ic_parcel.png",
                                    ),
                                  ),
                                  VTDivider(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Send something",
                                          style: AppTextStyle.copyWith(
                                            color: Color(0xFF333333),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TDivider(height: 6),
                                        Text(
                                          "We'll pick up and drop off your items",
                                          style: AppTextStyle.copyWith(
                                            color: Color(0xFFB9B9B9),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TDivider(),
                          InkWell(
                            onTap: () => openReceiveSomethingPage(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: Color(0xFFEFEFEF),
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: backgroundColor,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    width: 60,
                                    height: 60,
                                    child: Image.asset(
                                      "assets/icons/ic_parcel.png",
                                    ),
                                  ),
                                  VTDivider(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Receive something",
                                          style: AppTextStyle.copyWith(
                                            color: Color(0xFF333333),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TDivider(height: 6),
                                        Text(
                                          "We'll pick up and drop off your items",
                                          style: AppTextStyle.copyWith(
                                            color: Color(0xFFB9B9B9),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TDivider(),
                          InkWell(
                            onTap: () => openBuySomethingPage(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: Color(0xFFEFEFEF),
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: backgroundColor,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    width: 60,
                                    height: 60,
                                    child: Image.asset(
                                      "assets/icons/ic_bag.png",
                                    ),
                                  ),
                                  VTDivider(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Buy something",
                                          style: AppTextStyle.copyWith(
                                            color: Color(0xFF333333),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TDivider(height: 6),
                                        Text(
                                          "We'll purchase and delivery whatever you need",
                                          style: AppTextStyle.copyWith(
                                            color: Color(0xFFB9B9B9),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isOffline,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              "assets/images/closed.png",
                            ),
                            Text(
                              "Sorry we are offline",
                              style: AppTextStyle.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              "TandoorPlus active hours are: ${TandoorMenu.tandoorAppConfig["active_hours"].toString().replaceAll("-", " - ")}",
                              style: AppTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconText extends StatelessWidget {
  final Key key;
  final String icon;
  final String text;
  final bool isSelected;
  final Function onTap;

  _HeaderIconText(this.key, this.icon, this.text, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: isSelected ? 1 : 0.5,
          child: Container(
            decoration: BoxDecoration(
                color: isSelected ? appPrimaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? appPrimaryColor : Colors.transparent,
                    blurRadius: 2.0,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 0.0),
                  )
                ]),
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  icon,
                  height: 22,
                ),
                Padding(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: getARFontSize(context, NormalSize.S_15),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 8.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FooterMenu extends StatelessWidget {
  final bool isSelected;
  final String icon;
  final String text;
  final Function onTap;

  FooterMenu(this.isSelected, this.icon, this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 10,
            width: 38,
            color: Colors.transparent,
            child: Stack(
              children: [
                Visibility(
                  visible: isSelected,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFC907),
                      shape: BoxShape.rectangle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            icon,
            height: 24,
          ),
          Divider(
            thickness: 0,
            height: 5,
          ),
          Text(
            text,
            style: TextStyle(
                color: isSelected ? Colors.black : Color(0xFF848484),
                fontSize: 12,
                fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  final Shop shop;
  final Function onTap;

  _ShopItem(this.shop, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (shop.available)
            onTap(shop);
          else
            showOkMessage(
              context,
              "Unavailable",
              "${shop.nameEnglish ?? shop.nameUrdu} is offline at this moment.",
            );
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ImageLoader(
                        imageUrl: shop?.imageUrl,
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        fit: BoxFit.fitWidth,
                        available: shop?.available,
                      ),
                      Visibility(
                        visible: shop?.distanceTime != null,
                        child: Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.1),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            child: Text(
                              "${shop?.distanceTimeString}"
                                  .replaceFirst(" min", "\nMIN"),
                              textAlign: TextAlign.center,
                              style: AppTextStyle.copyWith(
                                fontSize: 11,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.transparent,
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: MarqueeWidget(
                      child: Text(
                        shop.nameEnglish,
                        style: AppTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: MarqueeWidget(
                      child: Row(
                        children: [
                          Text(
                            "${shop?.nameUrdu == null ? "" : "${shop.nameUrdu} • "}${shop.address == null ? "" : shop.address.split(RegExp(r"\,")).map((e) => e.trim()).toList().join(" • ")}",
                            style: AppTextStyle.copyWith(
                              color: Color(0xFFD2D2D2),
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(
                          shop.distanceString,
                          style: AppTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          " away",
                          style: AppTextStyle.copyWith(
                            color: Color(0xFFD2D2D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.transparent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TABS {
  ROTI,
  SHOPS,
  DELIVERY,
}
