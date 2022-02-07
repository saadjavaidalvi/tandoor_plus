import 'package:firebase_auth/firebase_auth.dart';
import 'package:user/models/user_profile.dart';

class SocialSignInResult {
  AuthCredential authCredential;
  UserProfile userProfile;

  SocialSignInResult({this.authCredential, this.userProfile});
}
