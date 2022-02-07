import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/app_progress_bar.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/primary_confirm_button.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/order.dart';
import 'package:user/pages/order_page.dart';

class MartOrderSummaryPage extends StatefulWidget {
  static final String route = "mart_order_summary";

  @override
  _MartOrderSummaryPageState createState() => _MartOrderSummaryPageState();
}

class _MartOrderSummaryPageState extends State<MartOrderSummaryPage> {
  bool progressBarVisible;
  Order order;

  String estimatedTime = "...";
  double estimatedPrice;

  @override
  void initState() {
    super.initState();
    progressBarVisible = true;

    order = Get.find<Order>(tag: MartOrderTag);
    estimatedPrice = order.deliveryPrice;

    var directionsService = DirectionsService();
    var request = DirectionsRequest(
      origin:
          "${order.senderAddress.latitude},${order.senderAddress.longitude}",
      destination:
          "${order.senderAddress.latitude},${order.senderAddress.longitude}",
      travelMode: TravelMode.driving,
      waypoints: [
        DirectionsWaypoint(
          location:
              "${order.receiverAddress.latitude},${order.receiverAddress.longitude}",
        ),
      ],
    );

    directionsService.route(request, (response, status) {
      var stateToSet = () {};
      if (response.status == DirectionsStatus.ok) {
        double distance = 0;
        double time = 0;

        response.routes.forEach((route) {
          route.legs.forEach((leg) {
            distance += leg.distance.value;
            time += leg.duration.value;
          });
        });
        stateToSet = () {
          estimatedPrice = Order.calculateMartOrderDeliveryPrice(
            order.deliveryPrice,
            distance,
          );
          order.calculatePrices();
          order.eta = (time.toInt() + (10 * 60)) * 1000;
          order.estimatedDeliveryCharges = estimatedPrice;
          estimatedTime =
              "${Duration(milliseconds: order.eta).inMinutes} - ${Duration(milliseconds: order.eta).inMinutes + 5} mins";
          progressBarVisible = false;
        };
      } else {
        double distance = 2 *
            calculateDistance(
              order.senderAddress.latitude,
              order.senderAddress.longitude,
              order.receiverAddress.latitude,
              order.receiverAddress.longitude,
            );

        stateToSet = () {
          estimatedPrice = Order.calculateMartOrderDeliveryPrice(
              order.deliveryPrice, distance);
          order.calculatePrices();
          progressBarVisible = false;
        };
      }

      if (mounted) {
        setState(stateToSet);
      } else {
        stateToSet();
      }
    });
  }

  void placeOrder() async {
    order.uid = FirebaseAuth.instance.currentUser.uid;
    order.id = DatabaseManager.instance.orders.doc().id;
    order.subtotalPrice = 0;

    setState(() {
      progressBarVisible = true;
    });
    var orderIds = await DatabaseManager.instance.saveNewOrders([order], []);

    Navigator.of(context).pushReplacementNamed(
      OrderPage.route,
      arguments: orderIds[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: getAppBar(
          context,
          AppBarType.backOnly,
          title: "Order Confirmation",
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: Stack(
          children: [
            Container(
              color: Color(0xFFF9F9F6),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFEFEFEF),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.12),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Location",
                                style: AppTextStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              TDivider(),
                              RichText(
                                text: TextSpan(
                                  style: AppTextStyle.copyWith(
                                    fontSize: 16,
                                    color: Color(0xFF333333),
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "${order.senderAddress.toString()}   ",
                                    ),
                                    WidgetSpan(
                                      child: Icon(
                                        Icons.arrow_forward,
                                        size: 18,
                                        color: Color(0xFFC8C8C8),
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "   ${order.receiverAddress.toString()}",
                                    ),
                                  ],
                                ),
                              ),
                              TDivider(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Color(0xFFC8C8C8),
                                    size: 22,
                                  ),
                                  VTDivider(width: 8),
                                  Text(
                                    estimatedTime,
                                    style: AppTextStyle.copyWith(
                                      fontSize: 14,
                                      color: Color(0xFFC8C8C8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Visibility(
                                visible: !GetUtils.isNullOrBlank(
                                  order.groceryList,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TDivider(),
                                    Text(
                                      "Grocery List",
                                      style: AppTextStyle.copyWith(
                                        fontSize: 14,
                                        color: Color(0xFFC8C8C8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      GetUtils.isNullOrBlank(order.groceryList)
                                          ? "--"
                                          : order.groceryList,
                                      style: AppTextStyle.copyWith(
                                        fontSize: 14,
                                        color: Color(0xFFC8C8C8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TDivider(),
                              Text(
                                "Instructions",
                                style: AppTextStyle.copyWith(
                                  fontSize: 14,
                                  color: Color(0xFFC8C8C8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                GetUtils.isNullOrBlank(order.instructions)
                                    ? "--"
                                    : order.instructions,
                                style: AppTextStyle.copyWith(
                                  fontSize: 14,
                                  color: Color(0xFFC8C8C8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TDivider(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFEFEFEF),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.12),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total",
                                style: AppTextStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              TDivider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Estimated service fee",
                                      style: AppTextStyle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Rs. ${estimatedPrice - 5} - ${estimatedPrice + 5}",
                                    style: AppTextStyle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TDivider(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFEFEFEF),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.12),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pay with",
                                style: AppTextStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              TDivider(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF6600).withOpacity(0.03),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFFF6600),
                                      size: 32,
                                    ),
                                    VTDivider(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Captain must be paid in cash at drop off location for the total value",
                                        style: AppTextStyle.copyWith(
                                          color: Color(0xFFFF6600),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TDivider(),
                              Row(
                                children: [
                                  Image.asset(
                                    "assets/icons/ic_cod.png",
                                    width: 18,
                                  ),
                                  VTDivider(),
                                  Expanded(
                                    child: Text(
                                      "Cash on delivery",
                                      style: AppTextStyle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 2,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: PrimaryConfirmButton(
                      text: "Place Order",
                      enabled: true,
                      onPressed: placeOrder,
                    ),
                  ),
                ],
              ),
            ),
            AppProgressBar(visible: progressBarVisible),
          ],
        ),
      ),
    );
  }
}
