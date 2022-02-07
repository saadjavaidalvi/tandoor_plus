import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationChangeCallbacks {
  PhoneVerificationCompleted phoneVerificationCompleted;
  PhoneVerificationFailed verificationFailed;
  PhoneCodeSent codeSent;

  PhoneVerificationChangeCallbacks(
      {this.phoneVerificationCompleted,
      this.verificationFailed,
      this.codeSent});
}
