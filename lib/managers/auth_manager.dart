import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:user/common/shared.dart';
import 'package:user/models/phone_verification_change_callbacks.dart';
import 'package:user/models/social_sign_in_result.dart';
import 'package:user/models/user_profile.dart';

class AuthManager {
  static int timeoutDuration = 30;
  FirebaseAuth firebaseAuth;

  static AuthManager _instance;

  static AuthManager get instance {
    if (_instance == null) _instance = AuthManager._();
    return _instance;
  }

  AuthManager._() {
    firebaseAuth = FirebaseAuth.instance;
  }

  void sendSmsCode(String phoneNumber,
      PhoneVerificationChangeCallbacks phoneVerificationChangeCallbacks) {
    firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted:
            phoneVerificationChangeCallbacks.phoneVerificationCompleted,
        verificationFailed: phoneVerificationChangeCallbacks.verificationFailed,
        codeSent: phoneVerificationChangeCallbacks.codeSent,
        codeAutoRetrievalTimeout: (verificationId) {},
        timeout: Duration(seconds: timeoutDuration));
  }

  Future<String> signInWithCredentials(
      PhoneAuthCredential phoneAuthCredential) async {
    User user = firebaseAuth.currentUser;
    try {
      if (user == null)
        await firebaseAuth.signInWithCredential(phoneAuthCredential);
      else
        await user.reauthenticateWithCredential(phoneAuthCredential);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<SocialSignInResult> requestGoogleSignIn() async {
    try {
      GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      GoogleAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return SocialSignInResult(
        authCredential: credential,
        userProfile: UserProfile(
          email: googleUser.email,
          name: googleUser.displayName,
          photoUrl: googleUser.photoUrl,
          googleId: googleUser.id,
        ),
      );
    } catch (e) {
      printInfo("Error: $e");
      return null;
    }
  }

  Future<UserProfile> requestFacebookSignIn() async {
    // Todo
    return null;
    // try {
    //   FacebookLogin facebookLogin = FacebookLogin();
    //   FacebookLoginResult result = await facebookLogin.logIn(
    //     permissions: [
    //       FacebookPermission.publicProfile,
    //       FacebookPermission.email,
    //     ],
    //   );
    //
    //   if (result.status == FacebookLoginStatus.success) {
    //     FacebookAccessToken accessToken = result.accessToken;
    //     FacebookAuthCredential facebookAuthCredential =
    //         FacebookAuthProvider.credential(accessToken.token);
    //
    //     await firebaseAuth.currentUser
    //         .linkWithCredential(facebookAuthCredential);
    //
    //     FacebookUserProfile profile = await facebookLogin.getUserProfile();
    //
    //     UserProfile userProfile = UserProfile(
    //       uid: FirebaseAuth.instance.currentUser.uid,
    //       phone: FirebaseAuth.instance.currentUser.phoneNumber,
    //       email: await facebookLogin.getUserEmail(),
    //       name: profile.name,
    //       photoUrl: await facebookLogin.getProfileImageUrl(width: 100),
    //       facebookId: profile.userId,
    //     );
    //     await updateProfileAuthProfile(
    //         name: userProfile.name, photoUrl: userProfile.photoUrl);
    //     await DatabaseManager.instance.saveUserProfile(userProfile);
    //
    //     return userProfile;
    //   } else if (result.status == FacebookLoginStatus.error) {
    //     throw Exception("${result.error}");
    //   } else {
    //     return null;
    //   }
    // } catch (e) {
    //   printInfo("Error: $e");
    //   return null;
    // }
  }

  Future<String> linkWithSocial(
      AuthCredential authCredential, UserProfile userProfile) async {
    try {
      await firebaseAuth.currentUser.linkWithCredential(authCredential);
      await updateProfileAuthProfile(
          name: userProfile.name, photoUrl: userProfile.photoUrl);
    } on FirebaseAuthException catch (e) {
      printInfo("$e");
      if (e.message.contains("sensitive") && e.message.contains("recent"))
        return "require re-authenticate";
      else
        return "${e.message}";
    } catch (e) {
      printInfo("$e");
    }
    return null;
  }

  Future<SocialSignInResult> requestEmailSignIn(
      {@required String email, String password}) async {
    password = password ?? _getRandomString(10);
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: password);
    return SocialSignInResult(
      authCredential: credential,
      userProfile: UserProfile(
        email: email,
      ),
    );
  }

  Future<void> updateProfileAuthProfile({String name, String photoUrl}) async {
    await firebaseAuth.currentUser
        .updateProfile(displayName: name, photoURL: photoUrl);
  }

  String _getRandomString(int length) {
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }
}
