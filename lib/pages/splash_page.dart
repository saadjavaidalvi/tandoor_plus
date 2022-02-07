import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/managers/messaging_manager.dart';
import 'package:user/models/cart.dart';
import 'package:user/models/wallet.dart';
import 'package:user/pages/create_account_page.dart';
import 'package:user/pages/welcome_page.dart';

import 'home_page.dart';

class SplashPage extends StatefulWidget {
  static final String route = "splash";

  SplashPage() {
    getIt = GetIt.instance;
  }

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final int epochTill = getEpochOfDevice() + 500;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    initLibs();
  }

  void initLibs() async {
    await GetStorage.init();
    DirectionsService.init(DirectionsApiKey);
    getIt.registerSingleton<Wallet>(Wallet());
    bool areAccepted = areTermsAccepted();

    if (areAccepted) {
      proceedToNextPage(context);
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          child: _TermsConditionsDialog(() {
            Navigator.pop(dialogContext);
            proceedToNextPage(context);
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: Center(
            child: SizedBox(
              width: 200.0,
              child: Image.asset(
                "assets/images/tandoor_plus_logo.png",
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> proceedToNextPage(BuildContext context) async {
    await Firebase.initializeApp();
    MessagingManager _messagingManager = MessagingManager.instance;
    FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    DatabaseManager _databaseManager = DatabaseManager.instance;

    await _messagingManager.init();
    getIt.registerSingleton<Cart>(await Cart.newEmpty());

    User currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      openPage(context, WelcomePage.route);
    } else if (currentUser != null) {
      await _messagingManager.saveTokenToDb(
        _databaseManager,
        currentUser.uid,
      );
      if (currentUser.email == null || currentUser.email.isEmpty)
        openPage(context, CreateAccountPage.route);
      else
        openPage(context, HomePage.route);
    }
  }

  void openPage(BuildContext context, String route) async {
    await getLocationPermission();
    await remainingDelay();

    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> remainingDelay() {
    int delay = epochTill - getEpochOfDevice();
    printInfo("Delaying for ${delay}ms");
    return Future.delayed(Duration(milliseconds: delay));
  }
}

class _TermsConditionsDialog extends StatelessWidget {
  final void Function() onAccepted;

  _TermsConditionsDialog(this.onAccepted);

  @override
  Widget build(BuildContext context) {
    TextStyle inlineTextStyle = AppTextStyle;
    TextStyle linkTextStyle = AppTextStyle.apply(
        color: appPrimaryColor,
        // fontSize: 14,
        decoration: TextDecoration.underline);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "assets/images/tandoor_plus_logo.png",
            height: 50,
          ),
          Divider(
            thickness: 0,
            height: 12,
            color: Colors.transparent,
          ),
          Text(
            "TO KEEP YOU SAFE",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                      text: "By proceeding, you agree to the ",
                      style: inlineTextStyle),
                  TextSpan(
                    style: linkTextStyle,
                    text: "Terms of Service",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (await canLaunch(TermsAndConditionsUrl)) {
                          await launch(TermsAndConditionsUrl);
                        }
                      },
                  ),
                  TextSpan(text: " and ", style: inlineTextStyle),
                  TextSpan(
                    style: linkTextStyle,
                    text: "Privacy Policy",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (await canLaunch(PrivacyPolicyUrl)) {
                          await launch(PrivacyPolicyUrl);
                        }
                      },
                  ),
                  TextSpan(text: ".", style: inlineTextStyle),
                ],
              ),
            ),
          ),
          Divider(
            thickness: 0,
            height: 20,
            color: Colors.transparent,
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    acceptTerms();
                    onAccepted();
                  },
                  child: Text(
                    "I AGREE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: getARFontSize(context, NormalSize.S_22),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    SystemNavigator.pop(animated: true);
                  },
                  child: Text(
                    "CANCEL",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: getARFontSize(
                        context,
                        NormalSize.S_22,
                      ),
                      color: Colors.black45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
