import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user/common/primary_confirm_button.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/db_entities.dart';
import 'package:user/pages/contact_info_page.dart';

class MapPage extends StatefulWidget {
  static final String route = "map";
  static final LatLng defaultLatLng = LatLng(31.5121581, 74.2776719);

  final AddressEntity addressEntity;
  final ContactInfoType contactInfoType;
  final CameraPosition initialCameraPosition = CameraPosition(
    target: defaultLatLng,
    zoom: 14,
  );

  MapPage(this.addressEntity, this.contactInfoType);

  @override
  _MapPageState createState() => _MapPageState(contactInfoType);
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  String heading;
  String description;
  Widget mapMarker;

  GoogleMapController mapController;
  bool myLocationButtonEnabled;
  bool isConfirmDisabled;
  bool showMarker;

  AnimationController messageFadeAnimationController;
  Animation messageFadeAnimation;

  AnimationController markerFadeAnimationController;
  Animation markerFadeAnimation;

  _MapPageState(ContactInfoType contactInfoType) {
    switch (contactInfoType) {
      case ContactInfoType.PICKUP:
        heading = "Pick-up details";
        description = "Move to edit\npick-up";
        mapMarker = Image.asset(
          "assets/images/map_marker_pick.png",
          height: 74,
        );
        break;
      case ContactInfoType.DROP_OFF:
        heading = "Drop-off details";
        description = "Move to edit\ndrop-off";
        mapMarker = Image.asset(
          "assets/images/map_marker_drop.png",
          height: 106,
        );
        break;
      case ContactInfoType.TANDOOR_DROP_OFF:
      default:
        heading = "Delivery details";
        description = "Move map and point\nto your destination";
        mapMarker = Image.asset(
          "assets/images/map_marker.png",
          height: 106,
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    myLocationButtonEnabled = false;
    isConfirmDisabled = true;
    showMarker = false;

    setLocation(widget.initialCameraPosition);
    messageFadeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    messageFadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(messageFadeAnimationController);

    markerFadeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    markerFadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(markerFadeAnimationController);

    showMyLocationButton();
  }

  void showMyLocationButton() async {
    if (await getLocationPermission()) {
      setState(() {
        myLocationButtonEnabled = true;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          showMarker = true;
        });
        messageFadeAnimationController.forward();
        markerFadeAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    messageFadeAnimationController.dispose();
    markerFadeAnimationController.dispose();
    super.dispose();
  }

  void setLocation(CameraPosition position) {
    widget.addressEntity.lat = position.target.latitude;
    widget.addressEntity.lon = position.target.longitude;
    if (position.target == MapPage.defaultLatLng) {
      if (!isConfirmDisabled)
        setState(() {
          isConfirmDisabled = true;
        });
    } else {
      if (isConfirmDisabled)
        setState(() {
          isConfirmDisabled = false;
        });
    }
  }

  void saveAndClose() async {
    if (widget.contactInfoType == ContactInfoType.TANDOOR_DROP_OFF) {
      widget.addressEntity.lastUsed = await getEpoch();
      DatabaseManager.instance
          .addNewAddress(widget.addressEntity)
          .then((newAddressEntity) {
        printInfo(
            "MapPage is popping with city ${newAddressEntity.city} at id ${newAddressEntity.id}");
        Navigator.pop(context, newAddressEntity);
      });
    } else {
      Navigator.pop(context, widget.addressEntity);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.addressEntity.city == null) Navigator.pop(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          padding: EdgeInsets.symmetric(
                            vertical: MediaQuery.of(context).padding.top,
                          ),
                          onMapCreated: _onMapCreated,
                          onCameraMove: setLocation,
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: myLocationButtonEnabled,
                          myLocationEnabled: myLocationButtonEnabled,
                          mapToolbarEnabled: true,
                          markers: {
                            Marker(markerId: MarkerId("1")),
                          },
                          rotateGesturesEnabled: false,
                          initialCameraPosition: widget.initialCameraPosition,
                        ),
                        Positioned(
                          top: 100,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Visibility(
                              visible: isConfirmDisabled,
                              child: FadeTransition(
                                opacity: messageFadeAnimation,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF1A1A1A),
                                          Color(0xFF545252),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      description,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: appPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.fastOutSlowIn,
                          top: showMarker ? 0 : -1000,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: FadeTransition(
                            opacity: markerFadeAnimation,
                            child: Center(
                              child: IgnorePointer(
                                ignoring: true,
                                child: mapMarker,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.06),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 25,
                            right: 25,
                            bottom: 30,
                            top: 12,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                heading,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Divider(
                                height: (GetUtils.isNullOrBlank(
                                          widget.addressEntity.houseNo,
                                        ) &&
                                        GetUtils.isNullOrBlank(
                                          widget.addressEntity.area,
                                        ))
                                    ? 0
                                    : 10,
                                thickness: 0,
                                color: Colors.transparent,
                              ),
                              Visibility(
                                visible: !(GetUtils.isNullOrBlank(
                                      widget.addressEntity.houseNo,
                                    ) &&
                                    GetUtils.isNullOrBlank(
                                      widget.addressEntity.area,
                                    )),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.06),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16.0,
                                          right: 5,
                                        ),
                                        child: Image.asset(
                                          "assets/icons/ic_address.png",
                                          width: 40,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${widget.addressEntity?.houseNo}, ${widget.addressEntity?.area}"
                                                  .trim(),
                                              style: AppTextStyle,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              widget.addressEntity?.city ?? "",
                                              style: AppTextStyle.copyWith(
                                                color: Color(0xFFC8C8C8),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                EdgeInsets.zero)),
                                        child: Text(
                                          "Change",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: appPrimaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 0,
                          thickness: 2,
                          color: Colors.black.withOpacity(0.06),
                        ),
                        PrimaryConfirmButton(
                          text: "Confirm Location",
                          enabled: !isConfirmDisabled,
                          onPressed: saveAndClose,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 15,
                left: 15,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
