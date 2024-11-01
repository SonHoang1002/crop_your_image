import 'dart:async';
import 'dart:ui' as ui;
import 'package:crop_image_module/a_test/format_v2.dart';
import 'package:crop_image_module/a_test/image_cropper_v2.dart';
import 'package:crop_image_module/cropping/logic/cropper/errors.dart';
import 'package:crop_image_module/cropping/logic/shape.dart';
import 'package:flutter/material.dart';

/// an implementation of [ImageCropperV2] using image package
class CropGenerator {
  FutureOr<ui.Image> crop({
    required ui.Image original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormatV2 outputFormat = ImageFormatV2.jpeg,
    ImageShape shape = ImageShape.rectangle,
  }) async {
    if (topLeft.dx.isNegative ||
        topLeft.dy.isNegative ||
        bottomRight.dx.isNegative ||
        bottomRight.dy.isNegative ||
        topLeft.dx.toInt() > original.width ||
        topLeft.dy.toInt() > original.height ||
        bottomRight.dx.toInt() > original.width ||
        bottomRight.dy.toInt() > original.height) {
      throw InvalidRectError(topLeft: topLeft, bottomRight: bottomRight);
    }
    if (topLeft.dx > bottomRight.dx || topLeft.dy > bottomRight.dy) {
      throw NegativeSizeError(topLeft: topLeft, bottomRight: bottomRight);
    }
    var data;
    switch (shape) {
      case (ImageShape.rectangle):
        data = await _doCrop(
          original,
          topLeft: topLeft,
          size: Size(
            bottomRight.dx - topLeft.dx,
            bottomRight.dy - topLeft.dy,
          ),
        );
        break;

      case (ImageShape.circle):
        data = await _doCropCircle(
          original,
          topLeft: topLeft,
          size: Size(
            bottomRight.dx - topLeft.dx,
            bottomRight.dy - topLeft.dy,
          ),
        );
        break;
      default:
        break;
    }
    return data;
  }

  /// process cropping image.
  /// this method is supposed to be called only via compute()
  Future<ui.Image> _doCrop(
    ui.Image original, {
    required Offset topLeft,
    required Size size,
  }) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();

    ui.Canvas canvas = ui.Canvas(recorder);

    canvas.clipRect(
      ui.Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        size.width,
        size.height,
      ),
    );

    canvas.drawImage(original, Offset.zero, ui.Paint());

    return await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
  }

  /// process cropping image with circle shape.
  /// this method is supposed to be called only via compute()
  Future<ui.Image> _doCropCircle(
    ui.Image original, {
    required Offset topLeft,
    required Size size,
  }) async {
    Offset center = Offset(
      topLeft.dx + size.width / 2,
      topLeft.dy + size.height / 2,
    );

    ui.PictureRecorder recorder = ui.PictureRecorder();

    ui.Canvas canvas = ui.Canvas(recorder);

    canvas.clipRect(
      ui.Rect.fromCircle(
        center: center,
        radius: size.width / 2,
      ),
    );

    canvas.drawImage(original, Offset.zero, ui.Paint());

    return await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
  }
}
