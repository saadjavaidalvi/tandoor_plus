import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:user/common/shared.dart';

class TandoorMenu {
  static List<_ProductItem> _menu = [
    _ProductItem(
      id: "item_0_000",
      name: "Saada Roti",
      urduName: "سادہ روٹی",
      image: "assets/images/sada_roti.jpg",
      rate: 8,
    ),
    _ProductItem(
      id: "item_0_000_1",
      name: "Saada Roti | Madri",
      urduName: "سادہ روٹی مدری",
      image: "assets/images/sada_roti.jpg",
      rate: 8,
    ),
    _ProductItem(
      id: "item_0_001",
      name: "Khamiri Roti",
      urduName: "خمری روٹی",
      image: "assets/images/khamiri_roti.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_001_1",
      name: "Khamiri Roti | Madri",
      urduName: "خمری روٹی مدری",
      image: "assets/images/khamiri_roti.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_002",
      name: "Sada Naan",
      urduName: "سادہ نان",
      image: "assets/images/sada_naan.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_002_1",
      name: "Sada Naan | Thin",
      urduName: "سادہ نان باریک",
      image: "assets/images/sada_naan.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_002_2",
      name: "Sada Naan | Madra",
      urduName: "سادہ نان مدرہ",
      image: "assets/images/sada_naan.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_002_3",
      name: "Sada Naan | Red",
      urduName: "سادہ نان لال",
      image: "assets/images/sada_naan.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_002_4",
      name: "Sada Naan | Madra + Red",
      urduName: "سادہ نان مدرہ لال",
      image: "assets/images/sada_naan.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_003",
      name: "Kulcha",
      urduName: "کلچا",
      image: "assets/images/kulcha.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_003_1",
      name: "Kulcha | Thin",
      urduName: "کلچہ باریک",
      image: "assets/images/kulcha.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_003_2",
      name: "Kulcha | Madra",
      urduName: "کلچہ مدرہ",
      image: "assets/images/kulcha.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_003_3",
      name: "Kulcha | Red",
      urduName: "کلچہ لال",
      image: "assets/images/kulcha.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_003_4",
      name: "Kulcha | Madra + Red",
      urduName: "کلچہ مدرہ لال",
      image: "assets/images/kulcha.jpg",
      rate: 15,
    ),
    _ProductItem(
      id: "item_0_004",
      name: "Sada Tandoori Paratha",
      urduName: "ساڈا تندوری پراٹھا",
      image: "assets/images/sada_roti.jpg",
      rate: 35,
    ),
    _ProductItem(
      id: "item_0_005",
      name: "Khamiri Tandoori Paratha",
      urduName: "خمری تندوری پراٹھا",
      image: "assets/images/sada_roti.jpg",
      rate: 40,
    ),
    _ProductItem(
      id: "item_0_007",
      name: "Roghani Naan",
      urduName: "روگنی نان",
      image: "assets/images/roghani_naan.jpg",
      rate: 35,
    ),
    _ProductItem(
      id: "item_0_007_1",
      name: "Half Roghani Naan",
      urduName: "حالف روغنی نان",
      image: "assets/images/roghani_naan.jpg",
      rate: 25,
    ),
    _ProductItem(
      id: "item_0_006",
      name: "Alu Wala Naan",
      urduName: "الو والا نان",
      image: "assets/images/aloo_naan.png",
      rate: 50,
    ),
    _ProductItem(
      id: "item_0_008",
      name: "Besan wala Naan",
      urduName: "بیسن والا نان",
      image: "assets/images/aloo_naan.png",
      rate: 50,
    ),
  ];
  static Map<String, _ProductItem> _menuMap = {
    for (_ProductItem item in _menu) item.id: item
  };
  static Map<String, dynamic> _tandoorAppConfigDefault = {
    ...{for (_ProductItem item in _menu) item.id: item.rate},
    "delivery_charges": 40,
    "near_shop_delivery_charges": 20.0,
    "items_limit": 20,
    "phone_number": "+92 300 0570932",
    "build_number": 0,
    "active_hours": "00:00-24:00",
    "nearDistance": 100.0,
  };

  static Map<String, dynamic> tandoorAppConfig = _tandoorAppConfigDefault;
  static List<String> productIDs =
      List.generate(_menu.length, (index) => _menu[index].id);

  static Future<void> loadTandoorAppConfig() async {
    RemoteConfig config = await RemoteConfig.instance;

    config.setDefaults({"tandoor_plus_config": _tandoorAppConfigDefault});
    config.setConfigSettings(RemoteConfigSettings(
      minimumFetchInterval: Duration(minutes: 30),
      fetchTimeout: Duration(minutes: 30),
    ));

    try {
      await config.fetch();
      await config.activate();
    } catch (e) {
      printInfo("Error: $e");
      throw e;
    }

    dynamic obj =
        json.decode(config.getValue('tandoor_plus_config').asString());

    tandoorAppConfig.forEach((key, value) {
      if (obj[key] != null) {
        if (value is double) {
          tandoorAppConfig[key] = (obj[key] as int).toDouble();
        } else if (value is int) {
          tandoorAppConfig[key] = obj[key] as int;
        } else {
          tandoorAppConfig[key] = obj[key];
        }
      }
    });
  }

  static double getRateById(String id) {
    return double.parse("${tandoorAppConfig[id] ?? -1}");
  }

  static String getNameById(String id) => _menuMap[id].name ?? "";

  static String getUrduNameById(String id) => _menuMap[id].urduName ?? "";

  static String getImageById(String id) =>
      _menuMap[id].image ?? "assets/images/sada_roti.jpg";
}

// Product item without rate. because rate is stored in TandoorAppConfig
class _ProductItem {
  String id;
  String name;
  String urduName;
  String image;
  double rate;

  _ProductItem({
    @required this.id,
    @required this.name,
    @required this.urduName,
    @required this.image,
    @required this.rate,
  });
}
