import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:user/common/shared.dart';
import 'package:user/pages/phone_login_page.dart';

class WelcomePage extends StatelessWidget {
  static final String route = "welcome";

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ).createShader(Rect.fromLTRB(
                    0, rect.height / 1.5, rect.width, rect.height));
              },
              blendMode: BlendMode.darken,
              child: Image.asset(
                "assets/images/bg_welcome.jpg",
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
              ),
            ),
            Center(
              heightFactor: 6,
              child: SizedBox(
                width: 140,
                child: Image.asset("assets/images/tandoor_plus_logo.png"),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: FlatButton(
                      onPressed: () {
                        openSignInPage(context);
                      },
                      color: appPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 70.0),
                        child: Text(
                          "Continue",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void openSignInPage(BuildContext context) {
    Navigator.pushReplacementNamed(context, PhoneLoginPage.route);
  }
}
