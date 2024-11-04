import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
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
    );
  }
}

/// process cropping image.
/// this method is supposed to be called only via compute()
Uint8List _doCrop(
  Image original, {
  required Offset topLeft,
  required Size size,
}) {
  return Uint8List.fromList(
    encodePng(
      copyCrop(
        original,
        x: topLeft.dx.toInt(),
        y: topLeft.dy.toInt(),
        width: size.width.toInt(),
        height: size.height.toInt(),
      ),
    ),
  );
}

/// process cropping image with circle shape.
/// this method is supposed to be called only via compute()
Uint8List _doCropCircle(
  Image original, {
  required Offset topLeft,
  required Size size,
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

/// an implementation of [ImageCropperV2] using image package
class ImageImageCropperV2 {
  FutureOr<ui.Image> crop({
    required ui.Image original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormatV2? outputFormat = ImageFormatV2.jpeg,
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

    canvas.translate(-topLeft.dx, -topLeft.dy);

    canvas.drawImage(original, Offset.zero, ui.Paint());

    ui.Image renderUiImage = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );

    return renderUiImage;
  }

  /// process cropping image with circle shape.
  /// this method is supposed to be called only via compute()
  Future<ui.Image> _doCropCircle(
    ui.Image original, {
    required Offset topLeft,
    required Size size,
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
    return await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
  }
}
