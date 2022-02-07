import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/draggable_list_view.dart';
import 'package:user/common/shared.dart';
import 'package:user/common/tile_text.dart';
import 'package:user/models/address.dart';
import 'package:user/models/areas.dart';
import 'package:user/models/db_entities.dart';
import 'package:user/models/order.dart';
import 'package:user/pages/contact_info_page.dart';

import 'map_page.dart';

TextEditingController _addressController;
TextEditingController _houseController;
TextEditingController _nameController;
AddressEntity _addressEntity;

class AddressPage extends StatefulWidget {
  static final String route = "address";

  final ContactInfoType contactInfoType;

  AddressPage(this.contactInfoType) {
    _addressController = TextEditingController();
    _houseController = TextEditingController();
    _nameController = TextEditingController();
    _addressEntity = new AddressEntity();
  }

  @override
  _AddressPage createState() {
    return _AddressPage(contactInfoType);
  }
}

class _AddressPage extends State<AddressPage> {
  String heading;
  String description;

  bool nextButtonEnabled;
  bool citySelectorVisible;
  bool areaSelectorVisible;
  bool blockSelectorVisible;

  String selectedCity;
  String selectedArea;
  String selectedBlock;

  Areas areas = Areas.instance;

  Order order;

  _AddressPage(ContactInfoType contactInfoType) {
    try {
      order = Get.find<Order>(tag: MartOrderTag);
    } catch (e) {
      order = Order(type: 0);
    }

    switch (contactInfoType) {
      case ContactInfoType.PICKUP:
        heading = order.resolvedType == ORDER_TYPE.PARCEL
            ? "Pick-up Address"
            : "Address";
        description = "We need the address to find shop easily.";
        break;
      case ContactInfoType.DROP_OFF:
        heading = order.resolvedType == ORDER_TYPE.PARCEL
            ? "Drop-off Address"
            : "Delivery Address";
        description = "We need the address to find drop off location easily.";
        break;
      case ContactInfoType.TANDOOR_DROP_OFF:
      default:
        heading = "What's your address?";
        description =
            "We need your address to deliver fresh naans at your doorstep!";
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    nextButtonEnabled = false;
    citySelectorVisible = false;
    areaSelectorVisible = false;
    blockSelectorVisible = false;
    saveSelectedAreas(selectedBlock);
  }

  void showCitySelector() {
    setState(() {
      citySelectorVisible = true;
      areaSelectorVisible = false;
      blockSelectorVisible = false;
    });
  }

  void showAreaSelector(String city) {
    setState(() {
      selectedCity = city;
      citySelectorVisible = false;
      areaSelectorVisible = true;
      blockSelectorVisible = false;
    });
  }

  void showBlockSelector(String area) {
    setState(() {
      selectedArea = area;
      citySelectorVisible = false;
      areaSelectorVisible = false;
      blockSelectorVisible = true;
    });
  }

  void saveSelectedAreas(String block) {
    List<String> temp = [block, selectedArea, selectedCity];
    temp.removeWhere((element) => element == null);
    _addressController.text = temp.join(", ");

    setState(() {
      selectedBlock = block;
      citySelectorVisible = false;
      areaSelectorVisible = false;
      blockSelectorVisible = false;

      inputValueChanged(_addressController.text);
    });
  }

  void saveAddress() async {
    // Todo don't allow multiple addresses with same toTitle() results
    closeKeyboard(this.context);

    Order order;
    try {
      order = Get.find<Order>(tag: MartOrderTag);
    } catch (e) {
      order = Order(type: 0);
    }

    AddressEntity newAddressEntity = await Navigator.pushNamed(
      context,
      MapPage.route,
      arguments: [_addressEntity, widget.contactInfoType],
    ) as AddressEntity;

    if (newAddressEntity != null) {
      printInfo(
        "AddressPage is popping with city ${newAddressEntity.city} at id ${newAddressEntity.id}",
      );

      if (widget.contactInfoType == ContactInfoType.DROP_OFF) {
        order.receiverAddress = Address.fromAddressEnt(newAddressEntity);
      } else if (widget.contactInfoType == ContactInfoType.PICKUP) {
        order.senderAddress = Address.fromAddressEnt(newAddressEntity);
      }

      Navigator.pop(context, newAddressEntity);
    } else {
      _addressController.text =
          "${_addressEntity.area ?? ""}, ${_addressEntity.city ?? ""}";
      _houseController.text = _addressEntity.houseNo;
      _nameController.text = _addressEntity.buildingName ?? "";
      _addressEntity.lat = 0;
      _addressEntity.lon = 0;
    }
  }

  bool validInput() {
    return (order.resolvedType == ORDER_TYPE.SHOPPING &&
            widget.contactInfoType == ContactInfoType.PICKUP &&
            _addressController.text.trim().length > 1) ||
        (_addressController.text.trim().length > 1 &&
            _houseController.text.trim().length >= 1);
  }

  void inputValueChanged(value) {
    List<String> temp = [selectedBlock, selectedArea];
    temp.removeWhere((element) => element == null);

    _addressEntity.city = selectedCity;
    _addressEntity.area = temp.join(", ");
    _addressEntity.houseNo = _houseController.text;
    _addressEntity.buildingName = _nameController.text;

    if (validInput()) {
      if (!nextButtonEnabled)
        setState(() {
          nextButtonEnabled = true;
        });
    } else if (nextButtonEnabled) {
      setState(() {
        nextButtonEnabled = false;
      });
    }
  }

  void nextStep() {
    if (validInput())
      saveAddress();
    else {
      setState(() {
        nextButtonEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (nextButtonEnabled && !validInput()) nextButtonEnabled = false;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: getAppBar(
          context,
          AppBarType.backWithButton,
          backButtonEnabled: nextButtonEnabled,
          onBackPressed: () {
            Navigator.pop(context);
          },
          buttonText: "Next",
          onButtonPressed: nextStep,
        ),
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(24.0),
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
                      controller: _addressController,
                      onChanged: inputValueChanged,
                      readOnly: true,
                      onTap: showCitySelector,
                      decoration: InputDecoration(
                        labelText: "Enter Area",
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
                      controller: _houseController,
                      onChanged: inputValueChanged,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText:
                            "House No / Apt / Suite / Floor${order.resolvedType == ORDER_TYPE.SHOPPING && widget.contactInfoType == ContactInfoType.PICKUP ? " (Optional)" : ""}",
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
                  TextFormField(
                    controller: _nameController,
                    onChanged: inputValueChanged,
                    decoration: InputDecoration(
                      labelText: "Business or Building Name (Optional)",
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      labelStyle: TextStyle(color: Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
            DraggableListView(
              visible: citySelectorVisible,
              onHide: () {
                setState(() {
                  citySelectorVisible = false;
                });
              },
              children: [
                TitleListTile(
                  "Select City",
                  onBack: () {
                    setState(() {
                      citySelectorVisible = false;
                    });
                  },
                ),
                LabelListTitle("AVAILABLE CITIES", Colors.black),
                ...List.generate(
                  areas.availableCities?.length ?? 0,
                      (index) => SelectionListTitle(
                    areas.availableCities[index],
                    leadingImage: "assets/icons/ic_address2.png",
                    onTap: () => showAreaSelector(areas.availableCities[index]),
                  ),
                ),
                Visibility(
                  visible: (areas.unavailableCities?.length ?? 0) > 0,
                  child: LabelListTitle("COMING SOON", appPrimaryColor),
                ),
                ...List.generate(
                  areas.unavailableCities?.length ?? 0,
                      (index) => DisabledListTitle(
                    areas.unavailableCities[index],
                    "assets/icons/ic_address2.png",
                  ),
                ),
              ],
            ),
            DraggableListView(
              visible: areaSelectorVisible,
              animateIn: false,
              onHide: () {
                setState(() {
                  areaSelectorVisible = false;
                });
              },
              children: [
                TitleListTile(
                  "Select Area",
                  onBack: () {
                    setState(() {
                      areaSelectorVisible = false;
                    });
                  },
                ),
                LabelListTitle("AVAILABLE AREAS", Colors.black),
                ...List.generate(
                  selectedCity == null
                      ? 0
                      : (areas.availableAreas[selectedCity]?.length ?? 0),
                      (index) => SelectionListTitle(
                    areas.availableAreas[selectedCity][index],
                    leadingImage: "assets/icons/ic_address2.png",
                    onTap: () => showBlockSelector(
                        areas.availableAreas[selectedCity][index]),
                  ),
                ),
                Visibility(
                  visible: selectedCity != null &&
                      (areas.unavailableAreas[selectedCity]?.length ?? 0) > 0,
                  child: LabelListTitle("COMING SOON", appPrimaryColor),
                ),
                ...List.generate(
                  selectedCity == null
                      ? 0
                      : (areas.unavailableAreas[selectedCity]?.length ?? 0),
                      (index) => DisabledListTitle(
                      areas.unavailableAreas[selectedCity][index],
                      "assets/icons/ic_address2.png"),
                ),
              ],
            ),
            DraggableListView(
              visible: blockSelectorVisible,
              animateIn: false,
              onHide: () {
                setState(() {
                  blockSelectorVisible = false;
                });
              },
              children: [
                TitleListTile(
                  "Select Block",
                  onBack: () {
                    setState(() {
                      blockSelectorVisible = false;
                    });
                  },
                ),
                LabelListTitle("AVAILABLE BLOCKS", Colors.black),
                ...List.generate(
                  (selectedCity == null || selectedArea == null)
                      ? 0
                      : ((areas.availableBlocks[selectedCity] ??
                      {})[selectedArea]
                      ?.length ??
                      0),
                      (index) => SelectionListTitle(
                    areas.availableBlocks[selectedCity][selectedArea][index],
                    leadingImage: "assets/icons/ic_address2.png",
                    onTap: () => saveSelectedAreas(areas
                        .availableBlocks[selectedCity][selectedArea][index]),
                  ),
                ),
                Visibility(
                  visible: selectedCity != null &&
                      selectedArea != null &&
                      ((areas.unavailableBlocks[selectedCity] ??
                          {})[selectedArea]
                          ?.length ??
                          0) >
                          0,
                  child: LabelListTitle("COMING SOON", appPrimaryColor),
                ),
                ...List.generate(
                  (selectedArea != null || selectedArea == null)
                      ? 0
                      : ((areas.unavailableBlocks[selectedCity] ??
                      {})[selectedArea]
                      ?.length ??
                      0),
                      (index) => DisabledListTitle(
                      areas.unavailableBlocks[selectedCity][selectedArea]
                      [index],
                      "assets/icons/ic_address2.png"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
