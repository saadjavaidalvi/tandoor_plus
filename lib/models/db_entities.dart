class AddressEntity {
  int id;
  String houseNo;
  String area;
  String city;
  int lastUsed;
  String uid;
  double lat;
  double lon;
  String buildingName;
  String label;

  AddressEntity({this.id,
    this.houseNo,
    this.area,
    this.city,
    this.lastUsed,
    this.uid,
    this.lat,
    this.lon,
    this.buildingName,
    this.label});

  AddressEntity.fromMap(Map<String, dynamic> values) {
    id = values["id"];
    houseNo = values["houseNo"];
    area = values["area"];
    city = values["city"];
    lastUsed = values["lastUsed"];
    uid = values["uid"];
    lat = values["lat"];
    lon = values["lon"];
    buildingName = values["buildingName"];
    label = values["label"];
  }

  String toTitle() {
    String res = "${houseNo ?? ""}, ${area ?? ""}, ${city ?? ""}";
    String _buildingName =
        buildingName.trim().length == 0 ? null : buildingName;
    return _buildingName ??
        label ??
        "${res.substring(res[0] == "," ? 1 : 0, res.length >= 15 ? 15 : null).trim()}...";
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "houseNo": houseNo,
      "area": area,
      "city": city,
      "lastUsed": lastUsed,
      "uid": uid,
      "lat": lat,
      "lon": lon,
      "buildingName": buildingName,
      "label": label,
    };
  }
}

class ContactInfoEntity {
  int id;
  String name;
  String phoneNumber;
  String email;
  int lastUsed;
  String uid;

  ContactInfoEntity({this.id,
    this.name,
    this.phoneNumber,
    this.email,
    this.lastUsed,
    this.uid});

  ContactInfoEntity.fromMap(Map<String, dynamic> values) {
    id = values["id"];
    name = values["name"];
    phoneNumber = values["phoneNumber"];
    email = values["email"];
    lastUsed = values["lastUsed"];
    uid = values["uid"];
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "phoneNumber": phoneNumber,
      "email": email,
      "lastUsed": lastUsed,
      "uid": uid
    };
  }
}
