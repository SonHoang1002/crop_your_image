import 'dart:async';
import 'dart:ui' as ui;
import 'package:crop_image_module/a_test/format_v2.dart';
import 'package:crop_image_module/cropping/logic/shape.dart';
import 'package:flutter/material.dart';

/// Interface for cropping logic
abstract class ImageCropperV2<T> {
  const ImageCropperV2();

  FutureOr<ui.Image> call({
    required T original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormatV2 outputFormat,
    ImageShape shape,
  });
}
