import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/instructions_input.dart';
import 'package:user/common/primary_confirm_button.dart';
import 'package:user/common/shared.dart';
import 'package:user/models/order.dart';
import 'package:user/pages/send_something_page.dart';

class BuySomethingPage extends StatefulWidget {
  static final String route = "grocery_input";

  @override
  _BuySomethingPageState createState() => _BuySomethingPageState();
}

class _BuySomethingPageState extends State<BuySomethingPage> {
  String groceryList;
  String instructions;
  Order order;

  @override
  void initState() {
    super.initState();

    groceryList = "";
    instructions = "";

    order = Get.find<Order>(tag: MartOrderTag);
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

  void nextStep() {
    order.groceryList = groceryList.trim();
    order.instructions = instructions;
    Navigator.of(context).pushReplacementNamed(
      SendSomethingPage.route,
      arguments: false,
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
                        "Tell us what to buy",
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: TextFormField(
                        autofocus: false,
                        onChanged: (String value) {
                          setState(() {
                            groceryList = value ?? "";
                          });
                        },
                        minLines: 5,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: appPrimaryColor),
                            borderRadius: BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: appPrimaryColor),
                            borderRadius: BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          labelStyle: TextStyle(color: Colors.black38),
                          hintText:
                              "e.g. grocery list:\n\n- 2 Colgate toothpaste\n- 3 Lay Chips...",
                          hintStyle: AppTextStyle.copyWith(
                            color: Color(0xFFD2D2D2),
                          ),
                        ),
                      ),
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
                    TDivider(),
                    Padding(
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
                    PrimaryConfirmButton(
                      text: "Continue",
                      enabled: groceryList.trim().length >= 3,
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
