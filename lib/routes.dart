import 'package:flutter/cupertino.dart';
import 'package:user/models/db_entities.dart';
import 'package:user/models/shop.dart';
import 'package:user/pages/address_page.dart';
import 'package:user/pages/buy_something_page.dart';
import 'package:user/pages/chat_page.dart';
import 'package:user/pages/contact_info_page.dart';
import 'package:user/pages/create_account_page.dart';
import 'package:user/pages/enter_code_page.dart';
import 'package:user/pages/home_page.dart';
import 'package:user/pages/map_page.dart';
import 'package:user/pages/mart_order_summary_page.dart';
import 'package:user/pages/order_page.dart';
import 'package:user/pages/order_summary_page.dart';
import 'package:user/pages/phone_login_page.dart';
import 'package:user/pages/profile_page.dart';
import 'package:user/pages/send_something_page.dart';
import 'package:user/pages/shop_menu_view_page.dart';
import 'package:user/pages/shop_page.dart';
import 'package:user/pages/splash_page.dart';
import 'package:user/pages/transations_page.dart';
import 'package:user/pages/welcome_page.dart';
import 'package:user/pages/your_orders_page.dart';

import 'models/order.dart';

getRoutes() {
  return {
    SplashPage.route: (context) => SplashPage(),
    WelcomePage.route: (context) => WelcomePage(),
    PhoneLoginPage.route: (context) => PhoneLoginPage(),
    EnterCodePage.route: (context) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context as BuildContext).settings.arguments
              as Map<String, dynamic>;
      return EnterCodePage(
        arguments["phoneNumber"] as String,
        arguments["verificationType"] as CodeVerificationType,
      );
    },
    HomePage.route: (context) => HomePage(),
    AddressPage.route: (context) => AddressPage(
          ModalRoute.of(context).settings.arguments as ContactInfoType,
        ),
    MapPage.route: (context) {
      List<dynamic> args = ModalRoute.of(context).settings.arguments;
      return MapPage(args[0] as AddressEntity, args[1] as ContactInfoType);
    },
    OrderSummaryPage.route: (context) => OrderSummaryPage(),
    CreateAccountPage.route: (context) => CreateAccountPage(),
    ContactInfoPage.route: (context) {
      List<dynamic> args = ModalRoute.of(context).settings.arguments;
      return ContactInfoPage(
        args[0] as ContactInfoType,
        args.length > 1 ? args[1] : true,
      );
    },
    OrderPage.route: (context) {
      var arguments = ModalRoute.of(context).settings.arguments;
      if (arguments is List) {
        return OrderPage(arguments[0], arguments[1]);
      } else {
        return OrderPage(arguments as String, false);
      }
    },
    YourOrdersPage.route: (context) => YourOrdersPage(),
    ProfilePage.route: (context) => ProfilePage(),
    ShopPage.route: (context) {
      Object arg = ModalRoute.of(context).settings.arguments;
      return ShopPage(
        id: arg is String
            ? ModalRoute.of(context).settings.arguments as String
            : null,
        shop: arg is Shop
            ? ModalRoute.of(context).settings.arguments as Shop
            : null,
      );
    },
    TransactionsPage.route: (context) => TransactionsPage(),
    ChatPage.route: (context) {
      var arg = ModalRoute.of(context).settings.arguments;
      return ChatPage(arg as Order);
    },
    BuySomethingPage.route: (context) => BuySomethingPage(),
    SendSomethingPage.route: (context) => SendSomethingPage(
          (ModalRoute.of(context).settings.arguments ?? false) as bool,
        ),
    MartOrderSummaryPage.route: (context) => MartOrderSummaryPage(),
    ShopMenuViewPage.route: (context) {
      List<dynamic> args = ModalRoute.of(context).settings.arguments;
      return ShopMenuViewPage(
        args[0],
        args[1],
        args[2],
      );
    }
  };
}
