import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:user/common/spinning_logo.dart';

class ImageLoader extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final bool available;

  ImageLoader({
    this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.available = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget missingImage = Image.asset(
      available
          ? "assets/launcher/foreground.png"
          : "assets/images/loading_placeholder.png",
      width: width,
      height: height,
      fit: fit,
    );

    Widget _widget;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      _widget = CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (_, ___) => SpinningLogo(
          name: "assets/launcher/foreground.png",
        ),
        errorWidget: (_, __, ___) => missingImage,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      _widget = missingImage;
    }

    return _widget;
  }
}
