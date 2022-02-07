import 'package:get/get.dart';
import 'package:user/common/shared.dart';
import 'package:user/models/db_entities.dart';

class Address {
  double latitude;
  double longitude;
  String address;
  String city;
  String buildingName;

  Address(
    this.address,
    this.city, {
    this.latitude = 0,
    this.longitude = 0,
    this.buildingName,
  });

  Address.fromAddressEnt(AddressEntity addressEntity) {
    latitude = addressEntity?.lat;
    longitude = addressEntity?.lon;
    address = GetUtils.isNullOrBlank(addressEntity?.houseNo)
        ? addressEntity?.area
        : "${addressEntity?.houseNo}, ${addressEntity?.area}";
    city = addressEntity?.city;
    buildingName = addressEntity?.buildingName;
  }

  Address.fromMap(Map<String, dynamic> values) {
    latitude = toDouble(values["latitude"]) ?? 0;
    longitude = toDouble(values["longitude"]) ?? 0;
    address = values["address"];
    city = values["city"];
    buildingName = values["buildingName"];
  }

  Address clone() {
    return Address(
      address,
      city,
      latitude: latitude,
      longitude: longitude,
      buildingName: buildingName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "latitude": latitude,
      "longitude": longitude,
      "address": address,
      "city": city,
      "buildingName": buildingName
    };
  }

  String toString() {
    if (GetUtils.isNullOrBlank(address)) {
      return city;
    } else {
      return "$address, $city";
    }
  }
}
