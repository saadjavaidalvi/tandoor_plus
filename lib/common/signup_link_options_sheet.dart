import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/auth_manager.dart';
import 'package:user/models/social_sign_in_result.dart';
import 'package:user/models/user_profile.dart';

import 'draggable_list_view.dart';

class SignupLinkOptionsSheet extends StatefulWidget {
  final bool visible;
  final bool cancelable;
  final Function onHide;
  final Function changeProgressBarVisibility;
  final Function onDone;

  SignupLinkOptionsSheet({
    @required this.visible,
    this.cancelable = false,
    @required this.onHide,
    @required this.changeProgressBarVisibility,
    @required this.onDone,
  });

  @override
  _SignupLinkOptionsSheetState createState() => _SignupLinkOptionsSheetState();
}

class _SignupLinkOptionsSheetState extends State<SignupLinkOptionsSheet> {
  @override
  void initState() {
    super.initState();
  }

  void openGoogleSignup() async {
    widget.changeProgressBarVisibility(true);
    SocialSignInResult socialSignInResult =
        await AuthManager.instance.requestGoogleSignIn();
    widget.changeProgressBarVisibility(false);

    if (socialSignInResult != null) {
      widget.onDone(socialSignInResult);
    }
  }

  void openFacebookSignup() async {
    widget.changeProgressBarVisibility(true);
    UserProfile userProfile =
        await AuthManager.instance.requestFacebookSignIn();
    widget.changeProgressBarVisibility(false);

    if (userProfile != null) {
      widget.onDone(SocialSignInResult(userProfile: userProfile));
    }
  }

  void openEmailSignup() async {
    widget.onDone(SocialSignInResult());
  }

  @override
  Widget build(BuildContext context) {
    TextStyle inlineTextStyle = AppTextStyle.copyWith(color: Color(0xFF848484));
    TextStyle linkTextStyle = AppTextStyle.apply(
      color: appPrimaryColor,
    );

    return DraggableListView(
      visible: widget.visible,
      color: Colors.white,
      onHide: widget.onHide,
      cancelable: widget.cancelable,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          margin: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sign up or log in",
                style: AppTextStyle.copyWith(
                  fontSize: getARFontSize(context, NormalSize.S_22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(height: 10, color: Colors.transparent),
              Container(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 10)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    backgroundColor:
                        MaterialStateProperty.all(Color(0xFFDC4B3E)),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    elevation: MaterialStateProperty.all(0),
                  ),
                  onPressed: openGoogleSignup,
                  child: Container(
                    width: double.infinity,
                    height: 25,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            "Continue with Google",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          left: 15,
                          child: Image.asset(
                            "assets/icons/ic_google.png",
                            height: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Divider(height: 10, color: Colors.transparent),
              Visibility(
                visible: false,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 10)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      backgroundColor:
                          MaterialStateProperty.all(Color(0xFF4267B2)),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      elevation: MaterialStateProperty.all(0),
                    ),
                    onPressed: openFacebookSignup,
                    child: Container(
                      width: double.infinity,
                      height: 25,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Text(
                              "Continue with Facebook",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            child: Image.asset(
                              "assets/icons/ic_facebook.png",
                              height: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Divider(),
              Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.only(bottom: 10),
                height: 45,
                child: OutlineButton(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  onPressed: openEmailSignup,
                  textColor: appPrimaryColor,
                  borderSide: BorderSide(color: appPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Continue with Email",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: "By signing up you agree to our ",
                        style: inlineTextStyle),
                    TextSpan(
                      style: linkTextStyle,
                      text: "Terms and Conditions",
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
            ],
          ),
        ),
      ],
    );
  }
}
