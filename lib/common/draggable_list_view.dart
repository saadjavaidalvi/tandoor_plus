import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DraggableListView extends StatelessWidget {
  final bool visible;
  final bool animateIn;
  final List<Widget> children;
  final Function onHide;
  final Color color;
  final bool cancelable;

  DraggableListView({
    this.visible = true,
    this.animateIn = true,
    @required this.children,
    this.onHide,
    this.color,
    this.cancelable = true,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: WillPopScope(
        onWillPop: () async {
          if (visible && cancelable) {
            onHide();
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Visibility(
            visible: visible,
            child: _DraggableListView(
              animateIn: animateIn,
              children: children,
              onHide: onHide,
              color: color,
              cancelable: cancelable,
            ),
          ),
        ),
      ),
    );
  }
}

class _DraggableListView extends StatefulWidget {
  final bool animateIn;
  final List<Widget> children;
  final Function onHide;
  final Color color;
  final bool cancelable;

  _DraggableListView({
    this.animateIn = true,
    @required this.children,
    this.onHide,
    this.color,
    this.cancelable = true,
  });

  @override
  __DraggableListViewState createState() => __DraggableListViewState();
}

class __DraggableListViewState extends State<_DraggableListView>
    with SingleTickerProviderStateMixin {
  double borderRadius;
  AnimationController controller;
  Animation<Offset> offset;

  @override
  void initState() {
    super.initState();

    borderRadius = 18;

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animateIn?150:0),
    );
    offset = Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset.zero)
        .animate(controller);
  }

  bool bottomSheetNotificationListener(
      DraggableScrollableNotification draggableScrollableNotification) {
    if (draggableScrollableNotification.extent == 0) {
      if (widget.onHide != null) widget.onHide();
      setState(() {
        borderRadius = 18;
      });
    } else if (draggableScrollableNotification.extent == 1) {
      setState(() {
        borderRadius = 0;
      });
    } else if (draggableScrollableNotification.extent < 1 &&
        borderRadius == 0) {
      setState(() {
        borderRadius = 18;
      });
    }
    return true;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.forward();

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (widget.cancelable) {
              setState(() {
                borderRadius = 18;
              });
              if (widget.onHide != null) widget.onHide();
            }
          },
          child: Container(
            color: Color(0x66000000),
          ),
        ),
        SlideTransition(
          position: offset,
          child: SizedBox.expand(
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: bottomSheetNotificationListener,
              child: DraggableScrollableSheet(
                initialChildSize: 0.4,
                maxChildSize: 1,
                minChildSize: widget.cancelable ? 0 : 0.4,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: widget.color ?? Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        topRight: Radius.circular(borderRadius),
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
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Wrap(
                        children: widget.children,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
