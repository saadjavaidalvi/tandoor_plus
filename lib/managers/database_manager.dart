import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:user/common/shared.dart';
import 'package:user/models/chat.dart';
import 'package:user/models/db_entities.dart';
import 'package:user/models/near_shop_orders.dart';
import 'package:user/models/order.dart';
import 'package:user/models/shop.dart';
import 'package:user/models/shop_menu_item.dart';
import 'package:user/models/transactions.dart';
import 'package:user/models/user_profile.dart';

class DatabaseManager {
  FirebaseDatabase realtimeDb;
  FirebaseDatabase chatRealtimeDb;
  FirebaseStorage storage;
  CollectionReference users;
  CollectionReference shops;
  CollectionReference riders;
  DatabaseReference contact;
  DatabaseReference rates;
  CollectionReference orders;
  DatabaseReference fcmTokens;
  DatabaseReference payments;
  CollectionReference shopLocs;
  CollectionReference riderLocs;
  DatabaseReference searchRadius;
  DatabaseReference timeOffsetRef;
  CollectionReference menu;
  CollectionReference nearShopOrders;
  DatabaseReference walletRef;
  DatabaseReference transactionsRef;
  DatabaseReference chatAppRef;
  Reference chatImagesRef;
  Reference chatVoiceNotesRef;

  Dio dio;

  static int _deviceTimeOffset;

  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;

    WidgetsFlutterBinding.ensureInitialized();
    String databasesPath = await getDatabasesPath();
    _database = await openDatabase(join(databasesPath, 'tandoor_plus.db'),
        onCreate: _initDatabase, version: 1);
    printInfo("Database opened: ${_database.path}");
    return _database;
  }

  static DatabaseManager _instance;

  static DatabaseManager get instance {
    if (_instance == null) {
      _instance = DatabaseManager._();
    }
    return _instance;
  }

  DatabaseManager._() {
    realtimeDb = FirebaseDatabase.instance;
    chatRealtimeDb = FirebaseDatabase(
      databaseURL: "https://tandoor-plus-chats.firebaseio.com/",
    );
    storage = FirebaseStorage.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;
    db.settings = Settings(persistenceEnabled: true, cacheSizeBytes: -1);

    users = db.collection("users");
    shops = db.collection("shops");
    riders = db.collection("riders");
    contact = realtimeDb.reference().child("help").child("number");
    rates = realtimeDb.reference().child("rates");
    orders = db.collection("orders");
    fcmTokens = realtimeDb.reference().child("fcm_tokens");
    payments = realtimeDb.reference().child("payments");
    shopLocs = db.collection("shop_locs");
    riderLocs = db.collection("rider_locs");
    searchRadius = realtimeDb.reference().child("search_radius");
    timeOffsetRef = realtimeDb.reference().child(".info/serverTimeOffset");
    menu = db.collection("menu");
    nearShopOrders = db.collection("nearShopOrders");
    walletRef = realtimeDb.reference().child("wallet");
    transactionsRef = realtimeDb.reference().child("transactions");
    chatAppRef = chatRealtimeDb.reference().child("chats");
    chatImagesRef = storage.ref("chat_images");
    chatVoiceNotesRef = storage.ref("chat_voice_notes");

    dio = Dio(
      BaseOptions(
        baseUrl: SERVER_URL,
        headers: {
          Headers.acceptHeader: "application/json",
          Headers.contentTypeHeader: "application/json",
        },
      ),
    );
  }

  Future<void> _initDatabase(Database db, int version) async {
    await db.execute(
        "CREATE TABLE address(id INTEGER PRIMARY KEY, houseNo TEXT, area TEXT, city TEXT, lastUsed INTEGER DEFAULT 0, uid TEXT, lat DOUBLE DEFAULT 0, lon DOUBLE DEFAULT 0, buildingName TEXT, label TEXT);");
    await db.execute(
        "CREATE TABLE contact_info(id INTEGER PRIMARY KEY,name TEXT,phoneNumber TEXT,email TEXT,lastUsed INTEGER DEFAULT 0, uid TEXT);");
  }

  Future<List<AddressEntity>> getAddresses({String uid}) async {
    try {
      uid = uid ?? FirebaseAuth.instance.currentUser.uid;
      assert(uid != null);
      Database db = await database;

      final List<Map<String, dynamic>> maps = await db.query('address',
          where: "uid LIKE ?", whereArgs: [uid], orderBy: "lastUsed DESC");
      return List.generate(maps.length, (i) => AddressEntity.fromMap(maps[i]));
    } catch (e) {
      printInfo("Error: $e");
      return [];
    }
  }

  Future<List<ContactInfoEntity>> getContactInfos({String uid}) async {
    try {
      uid = uid ?? FirebaseAuth.instance.currentUser.uid;
      assert(uid != null);
      Database db = await database;

      final List<Map<String, dynamic>> maps = await db.query('contact_info',
          where: "uid LIKE ?", whereArgs: [uid], orderBy: "lastUsed DESC");
      return List.generate(
          maps.length, (i) => ContactInfoEntity.fromMap(maps[i]));
    } catch (e) {
      printInfo("Error: $e");
      return [];
    }
  }

  Future<AddressEntity> addNewAddress(AddressEntity addressEntity,
      {String uid}) async {
    try {
      assert(addressEntity.city != null &&
          addressEntity.area != null &&
          addressEntity.houseNo != null);
      uid = uid ?? FirebaseAuth.instance.currentUser.uid;
      assert(uid != null);
      Database db = await database;

      addressEntity.uid = addressEntity.uid ?? uid;
      await db.insert("address", addressEntity.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      List<Map<String, dynamic>> result =
          await db.rawQuery("SELECT * FROM address ORDER BY id DESC LIMIT 1");
      assert(result.length > 0);
      return AddressEntity.fromMap(result[0]);
    } catch (e) {
      printInfo("Error: $e");
      return null;
    }
  }

  Future<ContactInfoEntity> addNewContactInfo(
      ContactInfoEntity contactInfoEntity,
      {String uid}) async {
    try {
      if (contactInfoEntity?.name == null) return null;
      uid = uid ?? FirebaseAuth.instance.currentUser.uid;
      assert(uid != null);
      Database db = await database;

      contactInfoEntity.uid = contactInfoEntity.uid ?? uid;
      await db.insert("contact_info", contactInfoEntity.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      List<Map<String, dynamic>> result = await db
          .rawQuery("SELECT * FROM contact_info ORDER BY id DESC LIMIT 1");
      assert(result.length > 0);
      return ContactInfoEntity.fromMap(result[0]);
    } catch (e) {
      printInfo("Error: $e");
      return null;
    }
  }

  Future<void> saveToken(String uid, String token) async {
    DataSnapshot dataSnapshot = await fcmTokens.child("$uid").once();
    if (dataSnapshot?.value != token) return fcmTokens.child("$uid").set(token);
  }

  Future<List<String>> saveNewOrders(
    List<Order> orders,
    List<NearShopOrders> _nearShopOrdersList,
  ) async {
    assert(orders != null);
    assert(orders.length > 0);

    List<String> ids = [];
    List<Future<dynamic>> requests = [];

    for (NearShopOrders _nearShopOrders in _nearShopOrdersList) {
      requests.add(
        nearShopOrders.doc(_nearShopOrders.id).set(_nearShopOrders.toMap()),
      );
    }

    // Normal orders
    for (int i = 0; i < orders.length; i++) {
      Order order = orders[i];
      assert(order.uid != null);

      order.datetime = await getEpoch();
      DocumentReference doc = this.orders.doc(order.id);
      printInfo("Creating new order ${doc.id}");

      requests.add(doc.set(order.toMap()));

      ids.add(order.id);
    }

    await Future.wait(requests);

    return ids;
  }

  Future<void> saveUserProfile(UserProfile userProfile) async {
    userProfile.uid = userProfile.uid ?? FirebaseAuth.instance.currentUser.uid;
    if (userProfile.uid == null) {
      throw Exception("User is not logged in");
    }

    return users.doc(userProfile.uid).set(userProfile.toMap());
  }

  Future<dynamic> addOrderListener(
    String orderId,
    void onUpdate(Order order),
  ) async {
    assert(orderId != null);
    return orders
        .doc(orderId)
        .snapshots()
        .listen((DocumentSnapshot documentSnapshot) {
      onUpdate(Order.fromMap(documentSnapshot.data()));
    });
  }

  Future<List<Order>> getOrdersList({
    String uid,
    int limit = 5,
    int beforeDatetime,
    bool forceServerUpdated,
  }) async {
    try {
      if (limit > 0) {
        uid = uid ?? FirebaseAuth.instance.currentUser.uid;
        assert(uid != null);
        beforeDatetime = beforeDatetime ?? await getEpoch();
        var query = orders
            .where("uid", isEqualTo: uid)
            .where("datetime", isLessThan: beforeDatetime)
            .orderBy("datetime", descending: true)
            .limit(limit);
        QuerySnapshot querySnapshot = await query
            .get(forceServerUpdated ? GetOptions(source: Source.server) : null);

        return List.generate(
          querySnapshot.docs.length,
          (index) => Order.fromMap(querySnapshot.docs[index].data()),
        );
      } else {
        return [];
      }
    } catch (e) {
      printInfo("Error: $e");
      return null;
    }
  }

  Future<int> getTimeOffset() async {
    try {
      return await calculateTimeOffset().timeout(Duration(seconds: 5));
    } catch (e) {
      printInfo("Error: $e");
      return 0;
    }
  }

  Future<int> calculateTimeOffset() async {
    if (_deviceTimeOffset == null)
      _deviceTimeOffset = (await timeOffsetRef.once()).value as int;
    return _deviceTimeOffset;
  }

  Future<List<Shop>> getShopsNear(
      BuildContext context, Position position) async {
    try {
      Response response = await dio.post("/getNearbyShops", data: {
        "lat": position.latitude.toString(),
        "lng": position.longitude.toString(),
      });

      List<Shop> shops = [];
      List<dynamic> maps = response.data["data"];

      maps.forEach((element) {
        shops.add(Shop.fromMap(element));
      });

      return shops;
    } catch (e) {
      showOkMessage(context, "Failure", "Failed to get nearby shops");
      return [];
    }
  }

  Future<List<ShopMenuItem>> getMenuItems(String shopId) async {
    QuerySnapshot querySnapshot =
        await menu.where("shopId", isEqualTo: shopId).get();
    List<ShopMenuItem> items = [];
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      items.add(ShopMenuItem.fromMap(doc.data()));
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> getShopLocations(
      List<String> orderIds, List<String> shopIds) async {
    List<Map<String, dynamic>> result = [];

    List<Future<DocumentSnapshot>> locs = [];
    for (String shopId in shopIds) {
      locs.add(shopLocs.doc(shopId).get());
    }
    List<DocumentSnapshot> _locs = await Future.wait<DocumentSnapshot>(locs);

    for (int index = 0; index < shopIds.length; index++) {
      String shopId = shopIds[index];
      String orderId = orderIds[index];

      bool found = false;
      for (DocumentSnapshot documentSnapshot in _locs) {
        try {
          if (documentSnapshot.data() is Map &&
              documentSnapshot.get(FieldPath(["d", "uid"])) == shopId) {
            GeoPoint geoPoint = documentSnapshot.get("l") as GeoPoint;
            result.add({
              "shopId": shopId,
              "orderId": orderId,
              "loc": LatLng(geoPoint.latitude, geoPoint.longitude),
            });
            found = true;
            break;
          }
        } catch (e) {
          printInfo("Error parsing GeoPoint in getShopLocations error: ${e}");
        }
      }
      if (!found) result.add(null);
    }

    return result;
  }

  Future<Transactions> loadTransactions(
    String uid,
  ) async {
    DataSnapshot dataSnapshot = await transactionsRef.child(uid).once();
    Map<dynamic, dynamic> values = dataSnapshot.value;
    return Transactions.fromMap(values);
  }

  Future<StreamSubscription> connectToChat(
    String chatId, {
    @required void Function(Chat chat) init,
    @required void Function(ChatMessage newMessage) onNewMessage,
  }) async {
    await chatRealtimeDb.goOnline();
    chatAppRef.child(chatId).once().then((DataSnapshot value) {
      init(Chat.fromMap(value.key, value.value));
    });

    return chatAppRef.child(chatId).onChildAdded.listen(
      (event) {
        ChatMessage message = ChatMessage.fromMap(event.snapshot.value);
        onNewMessage(message);
      },
    );
  }

  Future<void> sendMessage(
    String chatId,
    String receiverId,
    String message,
    CHAT_MESSAGE_TYPE type,
  ) {
    var uid = FirebaseAuth.instance.currentUser.uid;
    DatabaseReference databaseReference = chatAppRef.child(chatId).push();

    ChatMessage _message = ChatMessage()
      ..id = databaseReference.key
      ..sender = uid
      ..receiver = receiverId
      ..type = type
      ..datetime = DateTime.now().millisecondsSinceEpoch
      ..value = message;

    return databaseReference.set(_message.toMap());
  }

  Future<String> uploadFile(
    Uint8List rawData,
    String extension,
    CHAT_MESSAGE_TYPE type,
  ) async {
    var uid = FirebaseAuth.instance.currentUser.uid;

    Reference storageRef;
    switch (type) {
      case CHAT_MESSAGE_TYPE.IMAGE:
        storageRef = chatImagesRef;
        break;
      case CHAT_MESSAGE_TYPE.VOICE:
        storageRef = chatVoiceNotesRef;
        break;
      case CHAT_MESSAGE_TYPE.TEXT:
      default:
    }

    if (storageRef != null) {
      try {
        var taskSnapshot = await storageRef
            .child("${uid}_${getEpochOfDevice()}$extension")
            .putData(rawData);
        if (taskSnapshot.state == TaskState.success) {
          return taskSnapshot.ref.getDownloadURL();
        }
      } catch (e) {
        printInfo("Error: $e");
      }
    }
    return null;
  }
}
