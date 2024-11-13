import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:crop_image_module/cropping/helpers/enums.dart';
import 'package:crop_image_module/cropping/logic/cropper/errors.dart';
import 'package:crop_image_module/cropping/logic/cropper/image_cropper.dart';
import 'package:crop_image_module/cropping/logic/format_detector/format.dart'
    as format;
import 'package:crop_image_module/cropping/logic/format_detector/format.dart';
import 'package:crop_image_module/cropping/logic/shape.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart';

/// an implementation of [ImageCropper] using image package
class ImageImageCropper extends ImageCropper<Image> {
  const ImageImageCropper();

  @override
  FutureOr<Uint8List> call({
    required Image original,
    required Offset topLeft,
    required Offset bottomRight,
    required ExifStateMachine exifStateMachine,
    format.ImageFormat outputFormat = format.ImageFormat.jpeg,
    ImageShape shape = ImageShape.rectangle,
  }) {
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

    final function = switch (shape) {
      ImageShape.rectangle => _doCrop,
      ImageShape.circle => _doCropCircle,
    };

    return function(
      original,
      topLeft: topLeft,
      size: Size(
        bottomRight.dx - topLeft.dx,
        bottomRight.dy - topLeft.dy,
      ),
      exifStateMachine: exifStateMachine,
    );
  }

  /// process cropping image.
  /// this method is supposed to be called only via compute()
  Uint8List _doCrop(
    Image original, {
    required Offset topLeft,
    required Size size,
    required ExifStateMachine exifStateMachine,
  }) {
    Image transformedCroppedImage = copyCrop(
      original,
      x: topLeft.dx.toInt(),
      y: topLeft.dy.toInt(),
      width: size.width.toInt(),
      height: size.height.toInt(),
    );

    List<double> listTransform =
        exifStateMachine.currentResizeOrientation.getTransform();
    double rotate = -listTransform[0];
    double vFlipHorizontal = listTransform[1];
    double vFlipVertical = listTransform[2];

    if (rotate != 0) {
      transformedCroppedImage =
          copyRotate(transformedCroppedImage, angle: rotate);
    }
    if (vFlipHorizontal == -1) {
      transformedCroppedImage = flipHorizontal(transformedCroppedImage);
    }
    if (vFlipVertical == -1) {
      transformedCroppedImage = flipVertical(transformedCroppedImage);
    }

    return Uint8List.fromList(
      encodePng(transformedCroppedImage),
    );
  }

  /// process cropping image with circle shape.
  /// this method is supposed to be called only via compute()
  Uint8List _doCropCircle(
    Image original, {
    required Offset topLeft,
    required Size size,
    required ExifStateMachine exifStateMachine,
  }) {
    final center = Point(
      topLeft.dx + size.width / 2,
      topLeft.dy + size.height / 2,
    );
    return Uint8List.fromList(
      encodePng(
        copyCropCircle(
          original,
          centerX: center.xi,
          centerY: center.yi,
          radius: min(size.width, size.height) ~/ 2,
        ),
      ),
    );
  }
}

/// an implementation of [ImageCropperV2] using image package
class ImageImageCropperV2 {
  /// Used to crop uiImage from original image
  /// * [transformedImage] : uiImage is transformed with rotate, flip-x, flip-y
  /// * [topLeft] , [bottomRight] : Offset of target crop frame
  /// * [exifStateMachine] : Current status transform when crop
  /// * [isWithoutTransform] : If true -> return transformedImage, else -> return reversed transformImage
  FutureOr<ui.Image> crop({
    required ui.Image transformedImage,
    required Offset topLeft,
    required Offset bottomRight,
    required ExifStateMachine exifStateMachine,
    ImageFormatV2? outputFormat = ImageFormatV2.jpeg,
    ImageShape shape = ImageShape.rectangle,
    bool isWithoutTransform = true,
  }) async {
    if (topLeft.dx.isNegative ||
        topLeft.dy.isNegative ||
        bottomRight.dx.isNegative ||
        bottomRight.dy.isNegative ||
        topLeft.dx.toInt() > transformedImage.width ||
        topLeft.dy.toInt() > transformedImage.height ||
        bottomRight.dx.toInt() > transformedImage.width ||
        bottomRight.dy.toInt() > transformedImage.height) {
      throw InvalidRectError(topLeft: topLeft, bottomRight: bottomRight);
    }
    if (topLeft.dx > bottomRight.dx || topLeft.dy > bottomRight.dy) {
      throw NegativeSizeError(topLeft: topLeft, bottomRight: bottomRight);
    }
    var data;
    switch (shape) {
      case (ImageShape.rectangle):
        data = await _doCrop(
          transformedImage,
          topLeft: topLeft,
          size: Size(
            bottomRight.dx - topLeft.dx,
            bottomRight.dy - topLeft.dy,
          ),
          exifStateMachine: exifStateMachine,
          isWithoutTransform: isWithoutTransform,
        );
        break;

      case (ImageShape.circle):
        data = await _doCropCircle(
          transformedImage,
          topLeft: topLeft,
          size: Size(
            bottomRight.dx - topLeft.dx,
            bottomRight.dy - topLeft.dy,
          ),
          exifStateMachine: exifStateMachine,
          isWithoutTransform: isWithoutTransform,
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
    ui.Image transformedImage, {
    required Offset topLeft,
    required Size size,
    required bool isWithoutTransform,
    required ExifStateMachine exifStateMachine,
  }) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();

    ui.Canvas canvas = ui.Canvas(recorder);

    // render transformed image
    canvas.translate(-topLeft.dx, -topLeft.dy);

    canvas.drawImage(transformedImage, Offset.zero, ui.Paint());

    ui.Image renderUiImage = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );

    // reverse image to original form
    if (isWithoutTransform) {
      if (exifStateMachine.currentResizeOrientation !=
          EnumResizeOrientation.normal) {
        // reverse rotate and flipHorizontal, flipVertical
        ui.Image reverveImage = await _handleReverseWithTransform(
          renderUiImage: renderUiImage,
          exifStateMachine: exifStateMachine,
        );
        return reverveImage;
      }
    }

    return renderUiImage;
  }

  /// process cropping image with circle shape.
  /// this method is supposed to be called only via compute()
  Future<ui.Image> _doCropCircle(
    ui.Image original, {
    required Offset topLeft,
    required Size size,
    required ExifStateMachine exifStateMachine,
    bool isWithoutTransform = true,
  }) async {
    // Calculate the center of the circle
    Offset center = Offset(
      topLeft.dx + size.width / 2,
      topLeft.dy + size.height / 2,
    );

    // Create a PictureRecorder to record the drawing commands
    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas canvas = ui.Canvas(recorder);

    // Define a circular path for clipping
    Path clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: size.width / 2));

    // Apply the clipping path
    canvas.clipPath(clipPath);

    // Translate canvas to start drawing from topLeft
    canvas.translate(-topLeft.dx, -topLeft.dy);

    // Draw the original image on the canvas
    canvas.drawImage(original, Offset.zero, ui.Paint());

    // Convert the recorded picture to an image with specified width and height
    ui.Image renderUiImage = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
    if (isWithoutTransform) {
      if (exifStateMachine.currentResizeOrientation !=
          EnumResizeOrientation.normal) {
        // reverse rotate and flipHorizontal, flipVertical
        ui.Image reverveImage = await _handleReverseWithTransform(
          renderUiImage: renderUiImage,
          exifStateMachine: exifStateMachine,
        );
        return reverveImage;
      }
    }

    return renderUiImage;
  }

  /// Function is used to invert rotate , flipHorizontal, flipVertical
  ///
  /// * [renderUiImage] is image that is generate with transform
  /// * [rotate] is rotation value that is rotate original image to generate [renderUiImage] ( NOTE: pass rotate of image )
  /// * [isFlipX], [isFlipY] is flip value of image
  /// * [lastGestureTransformIndex] is value that is saved to announce that last user gesture is rotate, flipHorizontal, flipVertical or none
  ///
  Future<ui.Image> _handleReverseRotateFlip({
    required ui.Image renderUiImage,
    required ExifStateMachine exifStateMachine,
  }) async {
    List<double> rotateFlipXFlipY =
        exifStateMachine.currentResizeOrientation.getTransform();
    double rotate = rotateFlipXFlipY[0] / 360;
    double flipHorizontal = rotateFlipXFlipY[1];
    double flipVertical = rotateFlipXFlipY[2];

    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas canvas = ui.Canvas(recorder);

    double rotateReverse = -rotate;

    double absCos = cos(rotateReverse * pi * 2).abs();
    double absSin = sin(rotateReverse * pi * 2).abs();
    int newWidth =
        (renderUiImage.width * absCos + renderUiImage.height * absSin).round();
    int newHeight =
        (renderUiImage.width * absSin + renderUiImage.height * absCos).round();

    // Center the canvas
    canvas.translate(newWidth / 2, newHeight / 2);

    canvas.scale(flipHorizontal, flipVertical);
    canvas.rotate(rotateReverse * pi * 2);

    // Translate back to top-left corner
    canvas.translate(-renderUiImage.width / 2, -renderUiImage.height / 2);

    // Draw the image onto the canvas
    canvas.drawImage(renderUiImage, Offset.zero, ui.Paint());

    // Complete recording and create the final image with the new dimensions
    return await recorder.endRecording().toImage(newWidth, newHeight);
  }

  Future<ui.Image> _handleReverseWithTransform({
    required ui.Image renderUiImage,
    required ExifStateMachine exifStateMachine,
  }) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas canvas = ui.Canvas(recorder);

    Rect transformedRect = Rect.fromLTWH(
        0, 0, renderUiImage.width.toDouble(), renderUiImage.height.toDouble());

    Matrix4 matrix4 = exifStateMachine.currentResizeOrientation
        .getTransformByCenter(origin: transformedRect.center);

    Rect inversedRect =
        MatrixUtils.inverseTransformRect(matrix4, transformedRect);

    canvas.translate(
      -inversedRect.left - transformedRect.left,
      -inversedRect.top - transformedRect.top,
    );

    matrix4.invert();
    canvas.transform(matrix4.storage);

    canvas.drawImage(renderUiImage, Offset.zero, ui.Paint());

    return await recorder
        .endRecording()
        .toImage(inversedRect.width.toInt(), inversedRect.height.toInt());
  }
}
