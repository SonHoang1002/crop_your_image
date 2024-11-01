import 'dart:ui' as ui;
import 'package:crop_image_module/cropping/logic/parser/image_detail.dart';

/// Interface for parsing image and build [ImageDetail] from given [data].
typedef ImageParserV2 = ImageDetailV2 Function(
  ui.Image data,
);
