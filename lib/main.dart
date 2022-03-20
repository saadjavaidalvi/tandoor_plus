import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:user/pages/splash_page.dart';
import 'package:user/provider/cart_quantity_provider.dart';
import 'package:user/routes.dart';

import 'common/shared.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    child: MyApp(),
    providers: [
    ChangeNotifierProvider(create: (_)=>CartProvider(),),
  ]));
}

class MyApp extends StatelessWidget {
  // Todo: Use constant parameters: https://stackoverflow.com/a/52975018/5956174
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TandoorPlus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        primaryColor: appPrimaryColor,
        accentColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: GoogleFonts.nunitoSans().fontFamily,
      ),
      initialRoute: SplashPage.route,
      routes: getRoutes(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics()),
      ],
    );
  }
}
