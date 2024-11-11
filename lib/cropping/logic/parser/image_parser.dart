import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_image_module/cropping/logic/format_detector/format.dart';
import 'package:crop_image_module/cropping/logic/parser/image_detail.dart';

/// Interface for parsing image and build [ImageDetail] from given [data].
typedef ImageParser<T> = ImageDetail<T> Function(
  Uint8List data, {
  ImageFormat? inputFormat,
});

typedef ImageParserV2<T> = ImageDetailV2<T> Function(
  ui.Image data,
  Uint8List imageData, {
  ImageFormat? inputFormat,
});
