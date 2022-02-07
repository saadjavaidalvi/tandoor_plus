import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/auth_manager.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/managers/messaging_manager.dart';
import 'package:user/models/phone_verification_change_callbacks.dart';
import 'package:user/pages/create_account_page.dart';
import 'package:user/pages/home_page.dart';

TextEditingController codeEditingController;

enum CodeVerificationType { LOGIN, RE_LOGIN }

class EnterCodePage extends StatefulWidget {
  static final String route = "enter_code";
  final String phoneNumber;
  final AuthManager authManager = AuthManager.instance;
  final CodeVerificationType codeVerificationType;

  EnterCodePage(this.phoneNumber, this.codeVerificationType) {
    codeEditingController = TextEditingController();
  }

  @override
  _EnterCodePage createState() => _EnterCodePage();
}

class _EnterCodePage extends State<EnterCodePage> {
  bool isResendCodeVisible;
  int secondsLeftToResend;
  bool progressBarVisible;
  bool nextButtonEnabled;

  PhoneVerificationChangeCallbacks phoneVerificationChangeCallbacks;
  String verificationId;
  int forceResendToken;
  int resendTries;

  @override
  void initState() {
    super.initState();

    isResendCodeVisible = false;
    secondsLeftToResend = AuthManager.timeoutDuration;
    progressBarVisible = true;
    nextButtonEnabled = false;

    phoneVerificationChangeCallbacks = PhoneVerificationChangeCallbacks(
        phoneVerificationCompleted: (PhoneAuthCredential phoneAuthCredential) {
      setState(() {
        codeEditingController.text = phoneAuthCredential.smsCode;
        progressBarVisible = false;
      });
      signIn(phoneAuthCredential);
    }, verificationFailed: (FirebaseException e) {
      showOkMessage(context, "Error", e.message);
      setState(() {
        secondsLeftToResend = 0;
        isResendCodeVisible = true;
        progressBarVisible = false;
      });
      showOkMessage(context, "Failed", "Failed to send sms code.");
    }, codeSent: (verificationId, forceResendToken) {
      if (mounted) {
        setState(() {
          isResendCodeVisible = false;
          secondsLeftToResend = AuthManager.timeoutDuration;
          progressBarVisible = false;
          this.verificationId = verificationId;
        });
        setResendState();
      }
    });

    widget.authManager
        .sendSmsCode(widget.phoneNumber, phoneVerificationChangeCallbacks);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        appBar: getAppBar(context, AppBarType.backWithButton,
            backButtonEnabled: nextButtonEnabled,
            buttonText: "Submit", onBackPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        }, onButtonPressed: () {
          manualCodeVerify();
        }),
        body: Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Image.asset(
                        "assets/icons/ic_sms.png",
                        width: 48,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text("Enter the code",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        "Sent to ${widget.phoneNumber}.",
                        style: AppTextStyle.copyWith(fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: PinCodeTextField(
                                appContext: context,
                                controller: codeEditingController,
                                length: 6,
                                pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(8),
                                    borderWidth: 1,
                                    activeColor: Colors.black,
                                    inactiveColor: Color(0xFFB3B3B3),
                                    selectedColor: Colors.black,
                                    disabledColor: Color(0xFFB3B3B3),
                                    fieldWidth: 48),
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                cursorColor: Colors.transparent,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp("[0-9]"))
                                ],
                                onChanged: (value) {
                                  if (value.length == 6 && !nextButtonEnabled) {
                                    setState(() {
                                      nextButtonEnabled = true;
                                    });
                                  } else if (nextButtonEnabled) {
                                    setState(() {
                                      nextButtonEnabled = false;
                                    });
                                  }
                                },
                                onCompleted: (value) {},
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: isResendCodeVisible,
                      child: GestureDetector(
                        onTap: resendCode,
                        child: Text(
                          "Resend Code",
                          style: TextStyle(
                              color: appPrimaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !isResendCodeVisible,
                      child: Text(
                        "Resend code after ${secondsLeftToResend}s",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppProgressBar(visible: progressBarVisible),
            ],
          ),
        ),
      ),
    );
  }

  void setResendState() {
    if (secondsLeftToResend > 0) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            --secondsLeftToResend;
          });
        }
        setResendState();
      });
    } else {
      if (mounted) {
        setState(() {
          isResendCodeVisible = true;
        });
      }
    }
  }

  void manualCodeVerify() {
    var code = codeEditingController.text;
    if (code.length == 6 && isNumeric(code)) {
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: code);
      signIn(phoneAuthCredential);
    }
    setState(() {
      nextButtonEnabled = false;
      progressBarVisible = true;
    });
  }

  void resendCode() {
    setState(() {
      isResendCodeVisible = false;
      secondsLeftToResend = AuthManager.timeoutDuration;
      progressBarVisible = true;
      nextButtonEnabled = false;
    });
    widget.authManager
        .sendSmsCode(widget.phoneNumber, phoneVerificationChangeCallbacks);
  }

  signIn(PhoneAuthCredential phoneAuthCredential) {
    widget.authManager
        .signInWithCredentials(phoneAuthCredential)
        .then((result) {
      if (result == "success") {
        if (widget.codeVerificationType == CodeVerificationType.LOGIN) {
          MessagingManager.instance
              .saveTokenToDb(DatabaseManager.instance,
                  FirebaseAuth.instance.currentUser.uid)
              .then((value) async {
            bool isUserNew =
                (FirebaseAuth.instance.currentUser.email ?? "").isEmpty;
            Navigator.pop(context); // Pop this page
            Navigator.pop(context); // Pop Login page
            if (isUserNew)
              Navigator.pushNamed(context, CreateAccountPage.route);
            else
              Navigator.pushNamed(context, HomePage.route);
          });
        } else {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          nextButtonEnabled = true;
          progressBarVisible = false;
        });
        showOkMessage(
            context, "Failed", "Failed to verify code. Please try again.");
      }
    });
  }
}
