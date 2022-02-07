import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/draggable_list_view.dart';
import 'package:user/common/shared.dart';
import 'package:user/common/signup_link_options_sheet.dart';
import 'package:user/common/tile_text.dart';
import 'package:user/managers/auth_manager.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/social_sign_in_result.dart';
import 'package:user/models/user_profile.dart';
import 'package:user/pages/home_page.dart';
import 'package:user/pages/phone_login_page.dart';

import 'enter_code_page.dart';

TextEditingController _emailController;
TextEditingController _nameController;
TextEditingController _genderController;
TextEditingController _dobController;

class CreateAccountPage extends StatefulWidget {
  static final String route = "email_signup";

  CreateAccountPage() {
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _genderController = TextEditingController();
    _dobController = TextEditingController();
  }

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool nextButtonVisible;
  bool progressBarVisible;
  bool genderSelectorVisible;
  bool signUpWidgetVisible;
  DateTime dobSelected;

  AuthCredential authCredential;
  UserProfile userProfile;

  @override
  void initState() {
    super.initState();

    nextButtonVisible = false;
    progressBarVisible = false;
    genderSelectorVisible = false;
    signUpWidgetVisible = false;

    inputValueChanged("");

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        signUpWidgetVisible = true;
      });
    });
  }

  void inputValueChanged(String value) {
    bool validInput = !(!isEmail(_emailController.text.trim()) ||
        _nameController.text.trim().length < 3 ||
        _genderController.text.length == 0 ||
        _dobController.text.length == 0 ||
        dobSelected == null ||
        !isValidDob());

    if (validInput) {
      if (!nextButtonVisible)
        setState(() {
          nextButtonVisible = true;
        });
    } else if (nextButtonVisible)
      setState(() {
        nextButtonVisible = false;
      });
  }

  bool isValidDob({DateTime dob}) {
    dob = dob ?? dobSelected;
    return dob == null ||
        dob.isBefore(DateTime.now().subtract(Duration(days: 365 * 10)));
  }

  void signUpUser({UserProfile newUserProfile}) async {
    User currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      progressBarVisible = true;
    });

    if (newUserProfile == null) {
      if (userProfile == null) userProfile = UserProfile();
      userProfile.uid = currentUser.uid;
      userProfile.email = _emailController.text.trim();
      userProfile.name = _nameController.text.trim();
      userProfile.gender = _genderController.text;
      userProfile.phone = currentUser.phoneNumber;
      userProfile.dob = dobSelected.millisecondsSinceEpoch;
    }

    String errorMessage;

    if (userProfile.googleId != null)
      errorMessage = await AuthManager.instance
          .linkWithSocial(authCredential, userProfile);
    if (userProfile.facebookId != null)
      errorMessage = null; // already linked
    else {
      errorMessage = await AuthManager.instance.linkWithSocial(
        (await AuthManager.instance
                .requestEmailSignIn(email: userProfile.email))
            .authCredential,
        userProfile,
      );
    }

    if (errorMessage == "require re-authenticate") {
      if (!await reLoginUser(currentUser.phoneNumber)) return;
      signUpUser(newUserProfile: userProfile);
    } else if (errorMessage == null) {
      await DatabaseManager.instance.saveUserProfile(userProfile);
      Navigator.pushReplacementNamed(context, HomePage.route);
    } else {
      showOkMessage(context, "Failed", errorMessage);
    }
    setState(() {
      progressBarVisible = false;
    });
  }

  Future<bool> reLoginUser(String phoneNumber) async {
    bool result = await Navigator.pushNamed(
      context,
      EnterCodePage.route,
      arguments: {
        "phoneNumber": phoneNumber,
        "verificationType": CodeVerificationType.RE_LOGIN,
      },
    ) as bool;
    return result ?? false;
  }

  void showGenderSelector() {
    String gender = userProfile?.gender;
    if (gender == null || gender.isEmpty) {
      setState(() {
        genderSelectorVisible = true;
      });
    }
  }

  void selectGender(String gender) {
    setState(() {
      genderSelectorVisible = false;
    });
    _genderController.text = gender;
    inputValueChanged("");
  }

  void showDobSelector() async {
    int dob = userProfile?.dob;

    if (dob == null || dob == 0) {
      DateTime _dob = await showDatePicker(
        context: context,
        initialDate: dobSelected ?? DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
      );

      if (_dob != null) {
        selectDate(_dob);
      }
    }
  }

  void selectDate(DateTime _dob) {
    setState(() {
      dobSelected = _dob;
      _dobController.text = datetimeToShortDate(dobSelected);
      inputValueChanged("");
    });
  }

  void checkSignUpDone(SocialSignInResult socialSignInResult) {
    setState(() {
      signUpWidgetVisible = false;
      userProfile = socialSignInResult?.userProfile;
      authCredential = socialSignInResult?.authCredential;

      _emailController.text = userProfile?.email;
      _nameController.text = userProfile?.name;
      _genderController.text = userProfile?.gender;
      if (userProfile?.dob != null) {
        DateTime dateTime =
            DateTime.fromMillisecondsSinceEpoch(userProfile?.dob);
        if (isValidDob(dob: dateTime)) selectDate(dateTime);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> genders = [
      {"label": "Male", "icon": Icons.supervised_user_circle_outlined},
      {"label": "Female", "icon": Icons.supervised_user_circle_outlined},
      {"label": "Others", "icon": Icons.supervised_user_circle_outlined},
    ];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        appBar: getAppBar(
          context,
          AppBarType.backWithButton,
          buttonText: nextButtonVisible ? "Save" : "Logout",
          onBackPressed: () => SystemNavigator.pop(animated: true),
          onButtonPressed: nextButtonVisible
              ? signUpUser
              : () => FirebaseAuth.instance.signOut().then((_) =>
                  Navigator.pushReplacementNamed(
                      context, PhoneLoginPage.route)),
        ),
        body: Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Image.asset(
                          "assets/icons/ic_signup.png",
                          width: 48,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          "Let's get you started!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          "First, create your TandoorPlus account",
                          style: AppTextStyle.copyWith(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: TextFormField(
                          controller: _emailController,
                          onChanged: inputValueChanged,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: userProfile?.email != null,
                          decoration: InputDecoration(
                            labelText: "Email",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            labelStyle: TextStyle(color: Colors.black38),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: TextFormField(
                          controller: _nameController,
                          onChanged: inputValueChanged,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: "Name",
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            labelStyle: TextStyle(color: Colors.black38),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: TextFormField(
                          controller: _genderController,
                          onChanged: inputValueChanged,
                          onTap: showGenderSelector,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Gender",
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            labelStyle: TextStyle(color: Colors.black38),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: TextFormField(
                          controller: _dobController,
                          onChanged: inputValueChanged,
                          onTap: showDobSelector,
                          readOnly: true,
                          decoration: InputDecoration(
                              labelText: "Date of Birth",
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              labelStyle: TextStyle(color: Colors.black38),
                              errorText: isValidDob() ? null : ""),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DraggableListView(
                visible: genderSelectorVisible,
                onHide: () {
                  setState(() {
                    genderSelectorVisible = false;
                  });
                },
                children: [
                  TitleListTile(
                    "Select Gender",
                    onBack: () {
                      setState(() {
                        genderSelectorVisible = false;
                      });
                    },
                  ),
                  ...List.generate(
                    genders.length,
                    (index) => SelectionListTitle(
                      genders[index]["label"],
                      leadingIcon: genders[index]["icon"],
                      onTap: () => selectGender(genders[index]["label"]),
                    ),
                  ),
                ],
              ),
              SignupLinkOptionsSheet(
                visible: signUpWidgetVisible,
                onHide: () {
                  setState(() {
                    signUpWidgetVisible = false;
                  });
                },
                changeProgressBarVisibility: (bool visible) {
                  setState(() {
                    progressBarVisible = visible;
                  });
                },
                onDone: checkSignUpDone,
              ),
              AppProgressBar(visible: progressBarVisible),
            ],
          ),
        ),
      ),
    );
  }
}
