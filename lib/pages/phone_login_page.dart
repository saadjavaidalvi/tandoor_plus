import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/shared.dart';
import 'package:user/pages/enter_code_page.dart';

TextEditingController _phoneInputController;

class PhoneLoginPage extends StatefulWidget {
  static final String route = "phone_login";

  PhoneLoginPage() {
    _phoneInputController = TextEditingController(text: null);
  }

  @override
  _PhoneLoginPageState createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  bool nextButtonEnabled;

  String countryCode;
  final pkCountryCode = "+92";
  final usCountryCode = "+1";

  @override
  void initState() {
    super.initState();
    nextButtonEnabled = false;

    countryCode = pkCountryCode;

    inputValueChanged(null);
  }

  bool validInput() {
    return isValidPhoneNumber(
      countryCode + _phoneInputController.text,
    );
  }

  void inputValueChanged(value) {
    if (validInput()) {
      if (!nextButtonEnabled)
        setState(() {
          nextButtonEnabled = true;
        });
    } else if (nextButtonEnabled) {
      setState(() {
        nextButtonEnabled = false;
      });
    }
  }

  void openEnterCodePage() {
    if (validInput()) {
      Navigator.pushNamed(
        context,
        EnterCodePage.route,
        arguments: {
          "phoneNumber": "$countryCode${_phoneInputController.text}",
          "verificationType": CodeVerificationType.LOGIN,
        },
      );
    } else {
      nextButtonEnabled = false;
    }
  }

  void showSwitchPhoneDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white70,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Pakistan"),
                    leading: Image.asset(
                      "assets/images/pk_flag.png",
                      width: 30,
                    ),
                    trailing: Text(pkCountryCode),
                    onTap: () {
                      setState(() {
                        countryCode = pkCountryCode;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text("USA"),
                    leading: Image.asset(
                      "assets/images/usa_flag.png",
                      width: 30,
                    ),
                    trailing: Text(usCountryCode),
                    onTap: () {
                      setState(() {
                        countryCode = usCountryCode;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (nextButtonEnabled && !validInput()) nextButtonEnabled = false;

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        appBar: getAppBar(
          context,
          AppBarType.backWithButton,
          buttonText: "Next",
          backButtonEnabled: nextButtonEnabled,
          onButtonPressed: () {
            if (validInput())
              openEnterCodePage();
            else {
              setState(() {
                nextButtonEnabled = false;
              });
            }
          },
          onBackPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            SystemNavigator.pop(animated: true);
          },
        ),
        body: Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Image.asset(
                    "assets/icons/ic_phone_number.png",
                    width: 48,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    "What's your number?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    "We'll text a code to verify your phone.",
                    style: AppTextStyle.copyWith(fontSize: 15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFB3B3B3), width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                showSwitchPhoneDialog();
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 30,
                                      color: Colors.black54,
                                    ),
                                    Text(
                                      countryCode,
                                      style: TextStyle(fontSize: 20),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          VerticalDivider(
                            color: Color(0xFFB3B3B3),
                            thickness: 2,
                            width: 0,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneInputController,
                              autofocus: true,
                              onChanged: inputValueChanged,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: countryCode == pkCountryCode
                                    ? "321 1234567"
                                    : "0123456789",
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16,
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              maxLines: 1,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(10)
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        "Changed your number? Find your account",
                        style: TextStyle(color: appPrimaryColor),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
