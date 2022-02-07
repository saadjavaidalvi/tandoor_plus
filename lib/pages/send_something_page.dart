import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/instructions_input.dart';
import 'package:user/common/primary_confirm_button.dart';
import 'package:user/common/shared.dart';
import 'package:user/models/order.dart';
import 'package:user/pages/contact_info_page.dart';
import 'package:user/pages/mart_order_summary_page.dart';

class SendSomethingPage extends StatefulWidget {
  static final String route = "send_something";

  final bool isReceiving;

  SendSomethingPage(this.isReceiving);

  @override
  _SendSomethingPageState createState() => _SendSomethingPageState();
}

class _SendSomethingPageState extends State<SendSomethingPage> {
  bool pickupEnabled;
  bool dropOffEnabled;
  String instructions;

  Order order;

  bool contactsListVisible;

  @override
  void initState() {
    super.initState();

    pickupEnabled = true;
    dropOffEnabled = false;

    order = Get.find<Order>(tag: MartOrderTag);
    instructions = order.instructions ?? "";
  }

  void showInstructionsDialog() {
    InstructionsInput.showInstructionsInput(context, instructions,
        (String instructions) {
      if (mounted) {
        this.setState(() {
          this.instructions = instructions;
        });
      } else {
        this.instructions = instructions;
      }
    });
  }

  void addPickUpLocation() async {
    await Navigator.of(context).pushNamed(
      ContactInfoPage.route,
      arguments: [ContactInfoType.PICKUP, widget.isReceiving],
    );
    var order = Get.find<Order>(tag: MartOrderTag);
    if (order.sender != null && order.senderAddress != null) {
      if (mounted) {
        setState(() {
          dropOffEnabled = true;
          this.order = order;
        });
      } else {
        dropOffEnabled = true;
        this.order = order;
      }
    }
  }

  void addDropOffLocation() async {
    await Navigator.of(context).pushNamed(
      ContactInfoPage.route,
      arguments: [ContactInfoType.DROP_OFF, !widget.isReceiving],
    );

    var order = Get.find<Order>(tag: MartOrderTag);
    if (mounted) {
      setState(() {
        this.order = order;
      });
    } else {
      this.order = order;
    }
  }

  void nextStep() async {
    order.instructions = instructions;

    Navigator.of(context).pushReplacementNamed(
      MartOrderSummaryPage.route,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: getAppBar(
          context,
          AppBarType.backOnly,
          onBackPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 72),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        order.resolvedType == ORDER_TYPE.PARCEL
                            ? "Get anything picked up and delivered"
                            : "Buy any grocery from desired place and get it delivered",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        "Our box can fix about 3 footballs and handle 7 kgs of weight.",
                        style: AppTextStyle.copyWith(fontSize: 15),
                      ),
                    ),
                    _LocationSelector(
                      enabled: pickupEnabled,
                      completed:
                          order.sender != null && order.senderAddress != null,
                      index: 1,
                      title: "Add pickup location",
                      onTap: addPickUpLocation,
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 36),
                      height: 24,
                      child: VerticalDivider(
                        color: Color(0xFFD2D2D2),
                        width: 0.5,
                      ),
                    ),
                    _LocationSelector(
                      enabled: dropOffEnabled,
                      completed: order.receiver != null &&
                          order.receiverAddress != null,
                      index: 2,
                      title: "Add drop-off location",
                      onTap: addDropOffLocation,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      offset: Offset(0, -2),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Visibility(
                      visible: order.resolvedType == ORDER_TYPE.PARCEL,
                      child: TDivider(),
                    ),
                    Visibility(
                      visible: order.resolvedType == ORDER_TYPE.PARCEL,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: showInstructionsDialog,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.edit,
                                    color: Color(0xFF848484),
                                    size: 23,
                                  ),
                                ),
                              ),
                              VTDivider(),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Instructions",
                                      style: AppTextStyle.copyWith(
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TDivider(height: 4),
                                    Text(
                                      GetUtils.isNullOrBlank(instructions)
                                          ? "Add instructions"
                                          : instructions.replaceAll("\n", ", "),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: AppTextStyle.copyWith(
                                        color: Color(0xFF848484),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    PrimaryConfirmButton(
                      text: "Continue",
                      enabled: order?.receiver != null &&
                          order?.receiverAddress != null &&
                          order?.sender != null &&
                          order?.senderAddress != null,
                      onPressed: nextStep,
                    ),
                    TDivider(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final bool enabled;
  final bool completed;
  final int index;
  final String title;
  final void Function() onTap;

  _LocationSelector({
    @required this.enabled,
    @required this.completed,
    @required this.index,
    @required this.title,
    @required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (enabled) onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: enabled ? appPrimaryColor : Color(0xFFD2D2D2),
            width: enabled ? 1 : 0.5,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completed ? appPrimaryColor : backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: completed
                    ? Icon(Icons.check, color: Colors.white, size: 26)
                    : Text(
                        "$index",
                        style: AppTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: enabled ? appPrimaryColor : Color(0xFF848484),
                        ),
                      ),
              ),
            ),
            VTDivider(),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle.copyWith(
                  color: Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
