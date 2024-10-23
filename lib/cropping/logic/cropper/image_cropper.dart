import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_image_module/cropping/logic/logic.dart';
import 'package:crop_image_module/cropping/logic/shape.dart';
import 'package:crop_image_module/cropping/logic/format_detector/format.dart';

/// Interface for cropping logic
abstract class ImageCropper<T> {
  const ImageCropper();

  FutureOr<Uint8List> call({
    required T original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormat outputFormat,
    ImageShape shape,
  });
}
