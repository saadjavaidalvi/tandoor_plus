import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/shared.dart';
import 'package:user/common/tile_text.dart';
import 'package:user/pages/phone_login_page.dart';

import 'your_orders_page.dart';

FirebaseAuth _firebaseAuth;

class ProfilePage extends StatefulWidget {
  static final route = "profile";

  ProfilePage() {
    _firebaseAuth = FirebaseAuth.instance;
  }

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool progressBarVisible;

  @override
  void initState() {
    super.initState();
    progressBarVisible = false;
  }

  void logoutUser() {
    showYesNoMessage(context, "Are you sure?", "Do you want to logout now?",
        onYes: () async {
      setState(() {
        progressBarVisible = true;
      });
      await _firebaseAuth.signOut();
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, PhoneLoginPage.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    User user = _firebaseAuth.currentUser;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        appBar: getAppBar(
          context,
          AppBarType.backOnly,
          title: "Profile",
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: Stack(
          children: [
            Visibility(
              visible: user != null,
              child: Container(
                color: Colors.white,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        color: appPrimaryColor,
                        padding: const EdgeInsets.all(25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? "",
                                    style: AppTextStyle.copyWith(
                                      fontSize: 24,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    user?.phoneNumber ?? "-",
                                    style: AppTextStyle.copyWith(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    user?.email ?? "-",
                                    style: AppTextStyle.copyWith(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 40,
                              child: user?.photoURL == null
                                  ? Icon(
                                      Icons.perm_identity,
                                      color: Colors.black38,
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(45),
                                      child: Image.network(user.photoURL),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      SelectionListTitle(
                        "My orders",
                        onTap: () {
                          Navigator.pushNamed(context, YourOrdersPage.route);
                        },
                      ),
                      Divider(height: 0),
                      SelectionListTitle(
                        "Help Center",
                        onTap: () {
                          showHelpMessage(context);
                        },
                      ),
                      Divider(height: 0),
                      SelectionListTitle(
                        "Terms and Conditions",
                        onTap: () async {
                          if (await canLaunch(TermsAndConditionsUrl)) {
                            await launch(TermsAndConditionsUrl);
                          }
                        },
                      ),
                      Divider(height: 0),
                      SelectionListTitle(
                        "Privacy Policy",
                        onTap: () async {
                          if (await canLaunch(PrivacyPolicyUrl)) {
                            await launch(PrivacyPolicyUrl);
                          }
                        },
                      ),
                      Divider(height: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(3),
                        backgroundColor: MaterialStateProperty.all(
                          appPrimaryColor,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: logoutUser,
                      child: Text(
                        "Logout",
                        style: AppTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AppProgressBar(
              visible: progressBarVisible,
            ),
          ],
        ),
      ),
    );
  }
}
