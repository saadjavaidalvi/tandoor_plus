import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:get/get.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/primary_confirm_button.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/address.dart' as address;
import 'package:user/models/contact_info.dart';
import 'package:user/models/db_entities.dart';
import 'package:user/models/order.dart';
import 'package:user/pages/address_page.dart';
import 'package:user/pages/map_page.dart';

TextEditingController _nameController;
TextEditingController _phoneController;

enum ContactInfoType {
  TANDOOR_DROP_OFF,
  PICKUP,
  DROP_OFF,
}

class ContactInfoPage extends StatefulWidget {
  static final String route = "contact_info";

  final ContactInfoType contactInfoType;

  ContactInfoPage(this.contactInfoType, [bool useCurrentPhone = true]) {
    String phoneNumber = "";
    if (useCurrentPhone) {
      phoneNumber = FirebaseAuth.instance.currentUser.phoneNumber;
      phoneNumber = "0${phoneNumber.substring(3)}";
    }
    _nameController = TextEditingController();
    _phoneController = TextEditingController(text: phoneNumber);
  }

  @override
  _ContactInfoPageState createState() => _ContactInfoPageState(contactInfoType);
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  bool inputIsValid;

  String heading;
  String description;
  String footerDescription;

  Order order;

  String nameLabel;
  String phoneNumberLabel;

  _ContactInfoPageState(ContactInfoType contactInfoType) {
    try {
      order = Get.find<Order>(tag: MartOrderTag);
    } catch (e) {
      order = Order(type: 0);
    }

    nameLabel = "Name";
    phoneNumberLabel = "Phone Number";

    switch (contactInfoType) {
      case ContactInfoType.DROP_OFF:
        heading = order.resolvedType == ORDER_TYPE.PARCEL
            ? "Who's receiving the package?"
            : "Where to deliver?";
        description =
            "The driver may contact the recipient to complete the delivery.";
        footerDescription =
            "I have received permission from the package recipient for TandoorPlus to send text messages to the mobile phone entered above.";
        break;
      case ContactInfoType.PICKUP:
        if (order.resolvedType == ORDER_TYPE.PARCEL) {
          heading = "Who's sending the package?";
        } else {
          heading = "Where to buy?";
          nameLabel = "Shop Name (Optional)";
          phoneNumberLabel = phoneNumberLabel + " (Optional)";
        }
        description = order.resolvedType == ORDER_TYPE.PARCEL
            ? "The driver may contact the sender to complete the delivery."
            : "You can add contact information of any desired store or leave it blank";
        footerDescription = order.resolvedType == ORDER_TYPE.PARCEL
            ? "I have received permission from sender for TandoorPlus to send text messages to the mobile phone entered above."
            : "";
        break;
      case ContactInfoType.TANDOOR_DROP_OFF:
      default:
        heading = "Who will receive the items?";
        description = "Please enter your contact details.";
        footerDescription = "";
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    inputIsValid = false;

    if (order.resolvedType == ORDER_TYPE.SHOPPING &&
        widget.contactInfoType == ContactInfoType.PICKUP) {
      _phoneController.text = "";
    }

    inputValueChanged("");
  }

  bool validInput() {
    return (order.resolvedType == ORDER_TYPE.SHOPPING &&
            widget.contactInfoType == ContactInfoType.PICKUP) ||
        _nameController.text.trim().length >= 3 &&
            isValidPhoneNumber(_phoneController.text);
  }

  void inputValueChanged(value) {
    if (validInput()) {
      if (!inputIsValid)
        setState(() {
          inputIsValid = true;
        });
    } else if (inputIsValid) {
      setState(() {
        inputIsValid = false;
      });
    }
  }

  void saveNewContactInfo() async {
    String phoneNumber = _phoneController.text.length > 0
        ? "+92${_phoneController.text.substring(1)}"
        : "";
    ContactInfoEntity contactInfoEntity = ContactInfoEntity(
      uid: FirebaseAuth.instance.currentUser.uid,
      name: _nameController.text,
      phoneNumber: phoneNumber,
    );

    if (widget.contactInfoType == ContactInfoType.TANDOOR_DROP_OFF) {
      ContactInfoEntity newContactInfo =
          await DatabaseManager.instance.addNewContactInfo(contactInfoEntity);
      Navigator.pop(context, newContactInfo);
    } else {
      var order = Get.find<Order>(tag: MartOrderTag);

      ContactInfo contactInfo = ContactInfo.fromContactInfoEntity(
        contactInfoEntity,
      );

      if (widget.contactInfoType == ContactInfoType.DROP_OFF) {
        order.receiver = contactInfo;
      } else {
        order.sender = contactInfo;
      }

      if (order.resolvedType == ORDER_TYPE.PARCEL ||
          widget.contactInfoType == ContactInfoType.DROP_OFF) {
        await Navigator.pushNamed(
          context,
          AddressPage.route,
          arguments: widget.contactInfoType,
        );
      } else {
        AddressEntity newAddressEntity = await Navigator.pushNamed(
          context,
          MapPage.route,
          arguments: [AddressEntity(city: ""), widget.contactInfoType],
        ) as AddressEntity;
        if (newAddressEntity != null) {
          printInfo(
            "AddressPage is popping with city ${newAddressEntity.city} at id ${newAddressEntity.id}",
          );

          order = Get.find<Order>(tag: MartOrderTag);
          if (widget.contactInfoType == ContactInfoType.DROP_OFF) {
            order.receiverAddress = address.Address.fromAddressEnt(
              newAddressEntity,
            );
          } else if (widget.contactInfoType == ContactInfoType.PICKUP) {
            order.senderAddress = address.Address.fromAddressEnt(
              newAddressEntity,
            );
          }
        }
      }
      Navigator.pop(context);
    }
  }

  void nextStep() {
    if (validInput())
      saveNewContactInfo();
    else {
      setState(() {
        inputIsValid = false;
      });
    }
  }

  void selectContact() async {
    final PhoneContact contact =
        await FlutterContactPicker.pickPhoneContact().onError(
      (_, __) => null,
    );
    if (contact?.phoneNumber?.number != null) {
      _phoneController.text = contact.phoneNumber.number
          .replaceFirst("+92", "0")
          .replaceFirst(RegExp(r'^0092'), "0")
          .replaceAll(" ", "");
      inputValueChanged("");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (inputIsValid && !validInput()) inputIsValid = false;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: getAppBar(
          context,
          widget.contactInfoType == ContactInfoType.TANDOOR_DROP_OFF
              ? AppBarType.backWithButton
              : AppBarType.backOnly,
          backButtonEnabled: inputIsValid,
          onBackPressed: () {
            Navigator.pop(context);
          },
          buttonText: "Save",
          onButtonPressed: nextStep,
        ),
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Image.asset(
                      "assets/icons/ic_address.png",
                      width: 48,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      heading,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      description,
                      style: AppTextStyle.copyWith(fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: TextFormField(
                      controller: _nameController,
                      onChanged: inputValueChanged,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: nameLabel,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        labelStyle: TextStyle(color: Colors.black38),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: TextFormField(
                      controller: _phoneController,
                      onChanged: inputValueChanged,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      decoration: InputDecoration(
                        hintText: "0312 1234567",
                        labelText: phoneNumberLabel,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        labelStyle: TextStyle(color: Colors.black38),
                        suffixIcon: ElevatedButton(
                          onPressed: selectContact,
                          style: ElevatedButton.styleFrom(
                            // primary: Colors.black87,
                            primary: appPrimaryColor,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              side: BorderSide(
                                color: Colors.black87,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.contacts,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Visibility(
                visible:
                    widget.contactInfoType != ContactInfoType.TANDOOR_DROP_OFF,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TDivider(
                          height: GetUtils.isNullOrBlank(footerDescription)
                              ? 0
                              : 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          footerDescription,
                          style: AppTextStyle.copyWith(
                            color: Color(0xFF848484),
                          ),
                        ),
                      ),
                      PrimaryConfirmButton(
                        enabled: inputIsValid,
                        text: "Confirm Recipient",
                        onPressed: nextStep,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
