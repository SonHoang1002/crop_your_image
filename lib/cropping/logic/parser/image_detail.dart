import 'dart:typed_data';

/// Image with detail information.
class ImageDetail<T> {
  ImageDetail({
    required this.image,
    required this.width,
    required this.height,
    required this.imageData
  });

  final T image;
  final double width;
  final double height;
  final Uint8List imageData;

  late final bool isLandscape = width >= height;
  late final bool isPortrait = width < height;
}

class ImageDetailV2<T> {
  ImageDetailV2({
    required this.image,
    required this.imageData,
    required this.width,
    required this.height,
  });

  final T image;
  final Uint8List imageData;
  final double width;
  final double height;

  late final bool isLandscape = width >= height;
  late final bool isPortrait = width < height;
}