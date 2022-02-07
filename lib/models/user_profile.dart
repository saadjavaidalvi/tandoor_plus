// For FireStore document
import 'package:user/common/shared.dart';

class UserProfile {
  String uid;
  String email;
  String name; // for backward compatibility
  String gender;
  String phone;
  int dob = 0;
  String s_dob;
  String photoUrl;
  String googleId;
  String facebookId;

  UserProfile({
    this.uid,
    this.email,
    this.name,
    this.gender,
    this.phone,
    this.dob = 0,
    this.photoUrl,
    this.googleId,
    this.facebookId,
  }) {
    this.s_dob = epochToShortDate(dob);
  }

  UserProfile.fromMap(Map<String, dynamic> values) {
    uid = values["uid"];
    email = values["email"];
    name = values["name"];
    name = values["name"];
    gender = values["gender"];
    phone = values["phone"];
    dob = values["dob"] ?? 0;
    s_dob = values["s_dob"];
    photoUrl = values["photoUrl"];
    googleId = values["googleId"];
    facebookId = values["facebookId"];
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "name": name,
      "gender": gender,
      "phone": phone,
      "dob": dob,
      "s_dob": s_dob,
      "photoUrl": photoUrl,
      "googleId": googleId,
      "facebookId": facebookId,
    };
  }
}
