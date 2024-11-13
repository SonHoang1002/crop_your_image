import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:crop_image_module/cropping/helpers/enums.dart';

class CropImageHelpers {
  /// [imageData] is original image
  ///
  /// [rotate]: is quarter value
  ///
  /// Used [lastGestureTransformIndex] to determine rotate or flip before
  ///
  /// * 0: None
  /// * 1: Rotate
  /// * 2: FlipX
  /// * 3: FlipY
  ///
  static Future<ui.Image> handleInitUiImageWithRotateFlip({
    required Uint8List imageData,
    required ExifStateMachine exifStateMachine,
  }) async {
    ui.Image image = await decodeImageFromList(imageData);
    ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    ui.Canvas canvas = ui.Canvas(pictureRecorder);
    Size newSize = tranformCanvas(
      canvas,
      image: image,
      exifStateMachine: exifStateMachine,
    );

    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    ui.Image result = await pictureRecorder
        .endRecording()
        .toImage(newSize.width.toInt(), newSize.height.toInt());
    return result;
  }

  static Future<ui.Image> handleInitUiImageWithTransform({
    required Uint8List imageData,
    required ExifStateMachine exifStateMachine,
  }) async {
    ui.Image image = await decodeImageFromList(imageData);

    ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    ui.Canvas canvas = ui.Canvas(pictureRecorder);

    Rect originalRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    Matrix4 matrix4 = exifStateMachine.currentResizeOrientation
        .getTransformByCenter(origin: originalRect.center);

    Rect transformedRect = MatrixUtils.transformRect(matrix4, originalRect);

    canvas.translate(
      -transformedRect.left - originalRect.left,
      -transformedRect.top - originalRect.top,
    );

    canvas.transform(matrix4.storage);

    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    ui.Image result = await pictureRecorder
        .endRecording()
        .toImage(transformedRect.width.toInt(), transformedRect.height.toInt());

    return result;
  }

  static Size tranformCanvas(
    ui.Canvas canvas, {
    required ui.Image image,
    required ExifStateMachine exifStateMachine,
  }) {
    List<double> rotateFlipXFlipY =
        exifStateMachine.currentResizeOrientation.getTransform();
    double rotate = rotateFlipXFlipY[0] / 360;
    double flipHorizontal = rotateFlipXFlipY[1];
    double flipVertical = rotateFlipXFlipY[2];
    double absCos = (math.cos(rotate * pi * 2)).abs();
    double absSin = (math.sin(rotate * pi * 2)).abs();
    int newWidth = (image.width * absCos + image.height * absSin).round();
    int newHeight = (image.width * absSin + image.height * absCos).round();

    // Calculate the transformation: translate to center, apply rotation, scaling, and  translate back
    canvas.translate(newWidth / 2, newHeight / 2);

    rotate = formatRotate(rotate);

    // var cropRectangle = Rect.fromLTWH(0, 0, 30, 20);
    // Matrix4Transform matrix4transform = Matrix4Transform();
    // matrix4transform =
    //     matrix4transform.rotate(90 / 180 * pi, origin: Offset(50, 50));
    // var newCropRectangle =
    //     MatrixUtils.transformRect(matrix4transform.m, cropRectangle);

    // Matrix4 inverseMatrix = Matrix4Transform.from(matrix4transform.m).m
    //   ..invert();

    // var neworiginRect =
    //     MatrixUtils.inverseTransformRect(matrix4transform.m, newCropRectangle);
    // var neworiginRect2 =
    //     MatrixUtils.transformRect(inverseMatrix, newCropRectangle);
    // consolelog(
    //     "new crop: $newCropRectangle, new origin rect: $neworiginRect, 2: $neworiginRect2");

    // rotate image

    canvas.rotate(rotate * pi * 2);
    canvas.scale(flipHorizontal, flipVertical);

    canvas.translate(-image.width / 2, -image.height / 2);
    return Size(newWidth.toDouble(), newHeight.toDouble());
  }

  /// Only get decimal part of double number
  ///
  /// Example
  ///  * 0.5   -> 0.5
  ///  * -0.5  -> -0.5
  ///  * 1     -> 0
  ///  * -1.25 -> -0.25
  static double formatRotate(double rotate) {
    String rotateValue = rotate.toString();
    if (rotateValue.contains(".")) {
      return double.parse(
          "${rotate < 0 ? "-" : ""}0.${rotate.toString().split(".").last}");
    } else {
      throw Exception("formatRotate error");
    }
  }
}
