import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/common/tandoor_menu.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/near_shop_orders.dart';
import 'package:user/models/order_item.dart';

// debug
const bool debug = kDebugMode;
const bool debugPrint = kDebugMode;

const String SERVER_URL = "https://asia-east2-tandoor-9df7e.cloudfunctions.net";
const String _KEY_TERMS_ACCEPTED = "terms_accepted";
const String DirectionsApiKey = "AIzaSyBYBzbK_z9OQ2MdAMCpAWykCZZdUw02I9k";

GetIt getIt;

GetStorage _storage;

GetStorage get storage {
  if (_storage == null) {
    _storage = GetStorage();
  }
  return _storage;
}

enum NormalSize { S_12, S_14, S_15, S_16, S_18, S_22 }

const TextStyle AppTextStyle = TextStyle(color: Color(0xFF1A1A1A));

const TermsAndConditionsUrl = "https://tandoorplus.com/terms-and-conditions";
const PrivacyPolicyUrl = "https://tandoorplus.com/privacy-policy";

const String MartOrderTag = "martOrder";

Color backgroundColor = Color(0xFFF9F9F6);
const Color appPrimaryColor = Color(0xFFFFC907);

void printInfo(String info) {
  if (debugPrint) print("TandoorInfo: $info");
}

void hideKeyboard() {
  SystemChannels.textInput.invokeMethod('TextInput.hide');
}

// Get font size calculated by aspect ratio of device
getARFontSize(BuildContext context, NormalSize normalSize) {
  if (normalSize == NormalSize.S_12)
    return MediaQuery.of(context).size.width * 0.031;
  if (normalSize == NormalSize.S_14)
    return MediaQuery.of(context).size.width * 0.03;
  if (normalSize == NormalSize.S_15)
    return MediaQuery.of(context).size.width * 0.038;
  if (normalSize == NormalSize.S_16)
    return MediaQuery.of(context).size.width * 0.04;
  if (normalSize == NormalSize.S_18)
    return MediaQuery.of(context).size.width * 0.046;
  if (normalSize == NormalSize.S_22)
    return MediaQuery.of(context).size.width * 0.056;
}

// Return true if user has accepted terms and conditions before
bool areTermsAccepted() {
  return storage.read(_KEY_TERMS_ACCEPTED) ?? false;
}

acceptTerms() {
  storage.write(_KEY_TERMS_ACCEPTED, true);
}

Future<int> getEpoch() async {
  try {
    return (await DatabaseManager.instance.getTimeOffset()) +
        getEpochOfDevice();
  } catch (e) {
    printInfo("Error: $e");
    return getEpochOfDevice();
  }
}

int getEpochOfDevice() {
  return (new DateTime.now()).millisecondsSinceEpoch.round();
}

bool isValidPhoneNumber(String phoneNumber) {
  phoneNumber = phoneNumber ?? "";

  int length;
  if (phoneNumber.startsWith("+92")) {
    length = 12;
    phoneNumber = phoneNumber.substring(1);
  } else if (phoneNumber.startsWith("92")) {
    length = 12;
  } else if (phoneNumber.startsWith("+1")) {
    length = 11;
    phoneNumber = phoneNumber.substring(1);
  } else if (phoneNumber.startsWith("03")) {
    length = 11;
  } else {
    length = 10;
  }

  return phoneNumber.length == length && isNumeric(phoneNumber);
}

bool isNumeric(String s) {
  return s != null && double.tryParse(s) != null;
}

void showOkMessage(BuildContext context, String title, String message,
    {bool cancelable = true, Function onDismiss}) {
  showDialog(
    context: context,
    barrierDismissible: cancelable,
    builder: (dialogContext) {
      return WillPopScope(
        onWillPop: () async => cancelable,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                if (onDismiss != null) onDismiss();
              },
              style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
            ),
          ],
        ),
      );
    },
  );
}

void showYesNoMessage(
  BuildContext context,
  String title,
  String message, {
  Function onYes,
  Function onNo,
  Color yesColor,
  Color noColor,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: title != null && title.isNotEmpty ? Text(title) : null,
        content: message != null && message.isNotEmpty ? Text(message) : null,
        actions: [
          ElevatedButton(
            child: Text(
              "Yes",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              if (onYes != null) onYes();
            },
            style: ButtonStyle(
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed))
                    return yesColor ?? Colors.grey;
                  return (yesColor ?? Colors.grey).withOpacity(0.8);
                },
              ),
            ),
          ),
          ElevatedButton(
            child: Text(
              "No",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              if (onNo != null) onNo();
            },
            style: ButtonStyle(
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed))
                    return noColor ?? appPrimaryColor;
                  return (noColor ?? appPrimaryColor).withOpacity(0.8);
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}

void showHelpMessage(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text("Help"),
        content: Text(
            "You can contact us for any kind of help via Call or WhatsApp:"),
        actions: [
          ElevatedButton.icon(
            icon: Icon(
              Icons.call,
              size: 20,
            ),
            label: Text(
              "Call",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              String url =
                  "tel:${TandoorMenu.tandoorAppConfig["phone_number"]}";
              canLaunch(url).then((value) => launch(url));
              Navigator.pop(dialogContext);
            },
            style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
          ),
          ElevatedButton.icon(
            icon: Image.asset(
              "assets/icons/ic_whatsapp.png",
              width: 20,
            ),
            label: Text(
              "WhatsApp",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              String url =
                  "whatsapp://send?phone=${TandoorMenu.tandoorAppConfig["phone_number"]}";
              canLaunch(url).then((value) => launch(url)).catchError((e) {
                printInfo("${e.message}");
              });
              Navigator.pop(dialogContext);
            },
            style: ButtonStyle(
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed))
                    return Color(0xFF25D366);
                  return Color(0xFF25D366).withOpacity(0.8);
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}

void showUpdateMessage(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text("Update Required"),
          content: Text(
              "There is a better version of TandoorPlus available on store!"),
          actions: [
            ElevatedButton(
              child: Text(
                "Exit",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                SystemNavigator.pop(animated: true);
              },
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed))
                      return Colors.grey;
                    return Colors.grey.withOpacity(0.8);
                  },
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: Image.asset(
                "assets/icons/ic_playstore.png",
                width: 20,
              ),
              label: Text(
                "Update",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                launch("market://details?id=pk.com.tandoor.user")
                    .then((value) => SystemNavigator.pop(animated: true))
                    .catchError((e) {
                  launch(
                      "https://play.google.com/store/apps/details?id=pk.com.tandoor.user");
                }).then((value) => SystemNavigator.pop(animated: true));
              },
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed))
                      return Colors.black;
                    return Colors.black.withOpacity(0.8);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showListPopup(BuildContext context, String title, List<String> items,
    void onItemSelected(int index)) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Container(
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            children:
                List.generate(items.length, (index) => Text(items[index])),
          ),
        ),
        actions: [
          ElevatedButton(
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            style: ButtonStyle(elevation: MaterialStateProperty.all(0)),
          ),
        ],
      );
    },
  );
}

void showShopChangeConfirmation(
  BuildContext context,
  String message, {
  Function onYes,
}) {
  showYesNoMessage(
    context,
    null,
    "You already have items in your cart from another section of the app. Do you want to remove all other items and add this?",
    onYes: onYes,
    yesColor: appPrimaryColor,
  );
}

bool isEmail(String email) {
  String p =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regExp = new RegExp(p);
  return regExp.hasMatch(email);
}

String epochToShortDate(int epoch) {
  if (epoch == 0) return "";
  DateTime dt = DateTime.fromMillisecondsSinceEpoch(epoch);
  return datetimeToShortDate(dt);
}

String datetimeToShortDate(DateTime dateTime) {
  if (dateTime == null) return "";
  final DateFormat formatter = DateFormat('MMM dd, yyyy');
  return formatter.format(dateTime);
}

String epochToShortTime(int epoch) {
  if (epoch == 0) return "";
  DateTime dt = DateTime.fromMillisecondsSinceEpoch(epoch);
  final DateFormat formatter = DateFormat('h:mm aa');
  return formatter.format(dt);
}

String epochToFormattedDatetime(int epoch) {
  if (epoch == null) return "";
  DateTime dt = DateTime.fromMillisecondsSinceEpoch(epoch);
  final DateFormat formatter = DateFormat('MMM dd, yyyy h:mm:ss aa');
  return formatter.format(dt);
}

double toDouble(value) {
  if (value == null) return null;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  return 0;
}

Future<bool> getLocationPermission() async {
  PermissionStatus status = await Permission.locationWhenInUse.request();
  return status.isGranted;
}

// Return distance in meters
double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = math.cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  double d = 12742 * math.asin(math.sqrt(a)) * 1000;
  // printInfo("Distance between $lat1, $lon1 and $lat2, $lon2 is $d");
  return d;
}

String getGreetings() {
  int hour = DateTime.now().hour;
  if (hour >= 4 && hour < 12)
    return "Good Morning";
  else if (hour >= 12 && hour < 17)
    return "Good Afternoon";
  else
    return "Good Evening";
}

bool isInActiveHours(int epoch) {
  assert(epoch != null);

  String activeHoursS =
      TandoorMenu.tandoorAppConfig["active_hours"].toString().trim();

  assert(RegExp(r"^\d\d:\d\d-\d\d:\d\d$").hasMatch(activeHoursS));
  if (!RegExp(r"^\d\d:\d\d-\d\d:\d\d$").hasMatch(activeHoursS)) return true;

  List<String> splits = activeHoursS.split(RegExp("-"));

  int origin = getHourZeroOf(epoch);
  int start = addFormattedTime(origin, splits[0]);
  int end = addFormattedTime(origin, splits[1]);

  return epoch >= start && epoch <= end;
}

// Add time that is in format 10:34 to given epoch
int addFormattedTime(int epoch, String time) {
  assert(epoch != null);
  assert(time != null);
  assert(RegExp(r"^\d\d:\d\d$").hasMatch(time));

  if (!RegExp(r"^\d\d:\d\d$").hasMatch(time)) return epoch;
  List<String> splits = time.split(RegExp(":"));

  return DateTime.fromMillisecondsSinceEpoch(epoch)
      .add(Duration(hours: int.parse(splits[0]), minutes: int.parse(splits[1])))
      .millisecondsSinceEpoch;
}

int getHourZeroOf(int epoch) {
  DateTime dt = DateTime.fromMillisecondsSinceEpoch(epoch);
  return DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch.round();
}

int calculateCartQuantity(List<OrderItem> orderItems) {
  int quantity = 0;
  for (OrderItem orderItem in orderItems) {
    if (orderItem.quantity > 0) quantity++;
  }
  return quantity;
}

void closeKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}

extension DoubleRoundTo on double {
  double roundTo(double roundTo) {
    return (this / roundTo).round() * roundTo;
  }
}

LatLng getCenterLatLong(List<LatLng> latLongList) {
  double pi = math.pi / 180;
  double xpi = 180 / math.pi;
  double x = 0, y = 0, z = 0;

  if (latLongList.length == 1) {
    return latLongList[0];
  }
  for (int i = 0; i < latLongList.length; i++) {
    double latitude = latLongList[i].latitude * pi;
    double longitude = latLongList[i].longitude * pi;
    double c1 = math.cos(latitude);
    x = x + c1 * math.cos(longitude);
    y = y + c1 * math.sin(longitude);
    z = z + math.sin(latitude);
  }

  int total = latLongList.length;
  x = x / total;
  y = y / total;
  z = z / total;

  double centralLongitude = math.atan2(y, x);
  double centralSquareRoot = math.sqrt(x * x + y * y);
  double centralLatitude = math.atan2(z, centralSquareRoot);

  return LatLng(centralLatitude * xpi, centralLongitude * xpi);
}

List<NearShopOrders> groupOrdersByCloseShops(
  CollectionReference nearShopOrdersRef,
  List<Map<String, dynamic>> shopLocs,
) {
  List<NearShopOrders> nearShopOrdersList = [];
  double nearDistance = TandoorMenu.tandoorAppConfig["nearDistance"];
  List<List<Map<String, dynamic>>> groups = [];

  for (Map<String, dynamic> shopLoc in shopLocs) {
    if (shopLoc == null) continue;
    shopLoc["done"] = false;
    for (List<Map<String, dynamic>> group in groups) {
      for (Map<String, dynamic> otherShopLoc in group) {
        LatLng latLngShop = shopLoc["loc"] as LatLng;
        LatLng latLngOtherShop = otherShopLoc["loc"] as LatLng;

        if (calculateDistance(
              latLngShop.latitude,
              latLngShop.longitude,
              latLngOtherShop.latitude,
              latLngOtherShop.longitude,
            ) <=
            nearDistance) {
          shopLoc["done"] = true;
          group.add(shopLoc);
          break;
        }
      }
      if (shopLoc["done"]) break;
    }
    if (!shopLoc["done"]) {
      groups.add([shopLoc]);
    }
  }

  for (List<Map<String, dynamic>> group in groups) {
    NearShopOrders nearShopOrders = NearShopOrders(
      id: nearShopOrdersRef.doc().id,
      shopIds: [],
      orderIds: [],
    );
    List<LatLng> locs = [];
    for (Map<String, dynamic> shopLoc in group) {
      nearShopOrders.shopIds.add(shopLoc["shopId"]);
      nearShopOrders.orderIds.add(shopLoc["orderId"]);
      locs.add(shopLoc["loc"] as LatLng);
    }
    LatLng centerLatLong = getCenterLatLong(locs);
    nearShopOrders.centerLat = centerLatLong.latitude;
    nearShopOrders.centerLon = centerLatLong.longitude;

    nearShopOrdersList.add(nearShopOrders);
  }

  return nearShopOrdersList;
}

//
// String getPhoneNumberFromText(String text) {
//   RegExp regExp1 = RegExp(
//       r"^\+92\s*-*\d{3}\s*-*\d{7}$"); // matches: +923004725357, +92 300 4725357 and +92-300-4725357
//   RegExp regExp2 = RegExp(
//       r"^0{0,1}\d{3}\s*-*\d{7}$"); // matches: 03004725357, 0300 4725357, 0300-4725357, 3004725357, 300 4725357 and 300-4725357
//   RegExp toRemove = RegExp(r"(\s|-|\+92)");
//
//   var match1 = regExp1.firstMatch(text);
//   var match2 = regExp2.firstMatch(text);
//
//   if (match1 != null) {
//     return match1.input.replaceAll(toRemove, "");
//   } else if (match2 != null) {
//     String res = match2.input.replaceAll(toRemove, "");
//     if (res.length >= 10)
//       return res.substring(res.length - 10);
//   }
//   return null;
// }
