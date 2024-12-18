import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_image_module/cropping/helpers/enums.dart';
import 'package:crop_image_module/cropping/logic/format_detector/format.dart';
import 'package:crop_image_module/cropping/logic/parser/errors.dart';
import 'package:crop_image_module/cropping/logic/parser/image_detail.dart';
import 'package:image/image.dart' as image;

import 'image_parser.dart';

/// Implementation of [ImageParserV2] using image package
/// Parsed image is represented as [ui.Image]
// ignore: prefer_function_declarations_over_variables
final ImageParserV2<ui.Image> imageImageParserV2 =
    (uiImage, imageData, {inputFormat}) {
  return ImageDetailV2(
    image: uiImage,
    imageData: imageData,
    width: uiImage.width.toDouble(),
    height: uiImage.height.toDouble(),
  );
};

/// Implementation of [ImageParser] using image package
/// Parsed image is represented as [image.Image]
// ignore: prefer_function_declarations_over_variables
final ImageParser<image.Image> imageImageParser = (
  Uint8List data,
  ExifStateMachine exifStateMachine, {
  ImageFormat? inputFormat,
  ui.Image? uiImage,
}) {
  image.Image? tempImage;
  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();
  try {
    tempImage = _decodeWith(data, format: inputFormat);
  } on InvalidInputFormatError {
    rethrow;
  }
  stopwatch.stop();
  log("imageImageParser decode image log: ${stopwatch.elapsedMilliseconds}.ms");

  stopwatch.start();
  // check orientation
  image.Image parsed = switch (tempImage?.exif.exifIfd.orientation ?? -1) {
    3 => image.copyRotate(tempImage!, angle: 180),
    6 => image.copyRotate(tempImage!, angle: 90),
    8 => image.copyRotate(tempImage!, angle: -90),
    _ => tempImage!,
  };

  // transform with exifStateMachine
  List<double> listTransform =
      exifStateMachine.currentResizeOrientation.getTransform();
  double angle = listTransform[0];
  double flipHorizontal = listTransform[1];
  double flipVertical = listTransform[2];

  if (angle != 0) {
    parsed = image.copyRotate(
      parsed,
      angle: listTransform[0],
    );
  }

  if (flipHorizontal == -1) {
    parsed = image.flipHorizontal(parsed);
  }
  if (flipVertical == -1) {
    parsed = image.flipVertical(parsed);
  }

  stopwatch.stop();
  Uint8List imageData = image.encodeJpg(parsed);
  return ImageDetail(
    image: parsed,
    width: parsed.width.toDouble(),
    height: parsed.height.toDouble(),
    imageData: imageData,
  );
};

image.Image? _decodeWith(Uint8List data, {ImageFormat? format}) {
  try {
    return switch (format) {
      ImageFormat.jpeg => image.decodeJpg(data),
      ImageFormat.png => image.decodePng(data),
      ImageFormat.bmp => image.decodeBmp(data),
      ImageFormat.ico => image.decodeIco(data),
      ImageFormat.webp => image.decodeWebP(data),
      _ => image.decodeImage(data),
    };
  } on image.ImageException {
    throw InvalidInputFormatError(format);
  }
}
