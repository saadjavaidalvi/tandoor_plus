import 'package:user/models/db_entities.dart';

class ContactInfo {
  String name;
  String phone;
  String email;

  ContactInfo({this.name, this.phone, this.email});

  ContactInfo.fromContactInfoEntity(ContactInfoEntity contactInfoEntity) {
    name = contactInfoEntity?.name;
    phone = contactInfoEntity?.phoneNumber;
    email = contactInfoEntity?.email;
  }

  ContactInfo.fromMap(Map<String, dynamic> values) {
    name = values["name"];
    phone = values["phone"];
    email = values["email"];
  }

  ContactInfo clone() {
    return ContactInfo(name: name, phone: phone, email: email);
  }

  Map<String, dynamic> toMap() {
    return {"name": name, "phone": phone, "email": email};
  }
}
