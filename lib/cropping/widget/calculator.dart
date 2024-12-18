import 'dart:developer' as dev;
import 'dart:math';
import 'package:crop_image_module/cropping/helpers/typedef.dart';
import 'package:crop_image_module/cropping/logic/parser/image_detail.dart';
import 'package:flutter/widgets.dart';

/// Calculation logics for various [Rect] data.
abstract class Calculator {
  const Calculator();

  /// calculates [ViewportBasedRect] of image to fit the screenSize.
  ViewportBasedRect imageRect(Size screenSize, double imageAspectRatio);

  /// calculates [ViewportBasedRect] of initial cropping area.
  ViewportBasedRect initialCropRect(Size screenSize,
      ViewportBasedRect imageRect, double aspectRatio, double sizeRatio);

  /// calculates initial scale of image to cover _CropEditor
  double scaleToCover(Size screenSize, ViewportBasedRect imageRect);

  /// calculates ratio of [targetImage] and [screenSize]
  double screenSizeRatio(ImageDetail targetImage, Size screenSize);

  /// calculates [ViewportBasedRect] of the result of user moving the cropping area.
  ViewportBasedRect moveRect(
    ViewportBasedRect original,
    double deltaX,
    double deltaY,
    ViewportBasedRect imageRect,
  ) {
    if (original.left + deltaX < imageRect.left) {
      deltaX = (original.left - imageRect.left) * -1;
    }
    if (original.right + deltaX > imageRect.right) {
      deltaX = imageRect.right - original.right;
    }
    if (original.top + deltaY < imageRect.top) {
      deltaY = (original.top - imageRect.top) * -1;
    }
    if (original.bottom + deltaY > imageRect.bottom) {
      deltaY = imageRect.bottom - original.bottom;
    }
    return Rect.fromLTWH(
      original.left + deltaX,
      original.top + deltaY,
      original.width,
      original.height,
    );
  }

  /// calculates [ViewportBasedRect] of the result of user moving the top-left dot.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  ViewportBasedRect moveTopLeft({
    required ViewportBasedRect original,
    required ViewportBasedRect imageRect,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    double? aspectRatio,
  }) {
    double newLeft = max(
      max(0, imageRect.left), // min limit
      min(original.left + deltaX, original.right - dotSize + 3), // max limit
    );

    double newTop = min(
      max(original.top + deltaY, max(0, imageRect.top)), // min limit
      original.bottom - dotSize + 3, // max limit
    );
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        newTop,
        original.right,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - newLeft;
        var newHeight = newWidth / aspectRatio;
        if (original.bottom - newHeight < imageRect.top) {
          newHeight = original.bottom - imageRect.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      } else {
        var newHeight = original.bottom - newTop;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      }
    }
  }

  /// calculates [ViewportBasedRect] of the result of user moving the top-right dot.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  /// * [viewportSize] -> Size of preview and gesture area
  ViewportBasedRect moveTopRight({
    required ViewportBasedRect original,
    required ViewportBasedRect imageRect,
    required Size viewportSize,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    double? aspectRatio,
  }) {
    double newTop = min(
      max(original.top + deltaY, max(0, imageRect.top)),
      original.bottom - dotSize + 3,
    );
    double newRight = max(
      min(original.right + deltaX, min(viewportSize.width, imageRect.right)),
      original.left + dotSize - 3,
    );
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        newTop,
        newRight,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = newRight - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.bottom - newHeight < imageRect.top) {
          newHeight = original.bottom - imageRect.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.bottom - newHeight,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = original.bottom - newTop;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.left,
          original.bottom - newHeight,
          original.left + newWidth,
          original.bottom,
        );
      }
    }
  }

  /// calculates [ViewportBasedRect] of the result of user moving the bottom-left dot.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  ViewportBasedRect moveBottomLeft({
    required ViewportBasedRect original,
    required ViewportBasedRect imageRect,
    required Size viewportSize,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    double? aspectRatio,
  }) {
    double newLeft = max(
      max(0, imageRect.left),
      min(original.left + deltaX, original.right - dotSize + 3),
    );
    double newBottom = max(
      min(original.bottom + deltaY, min(imageRect.bottom, viewportSize.height)),
      original.top + dotSize - 3,
    );

    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        original.top,
        original.right,
        newBottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - newLeft;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      } else {
        var newHeight = newBottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      }
    }
  }

  /// calculates [ViewportBasedRect] of the result of user moving the bottom-right dot.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  /// * [viewportSize] -> Size of preview and gesture area
  ViewportBasedRect moveBottomRight({
    required ViewportBasedRect original,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    required ViewportBasedRect imageRect,
    required Size viewportSize,
    double? aspectRatio,
  }) {
    double newRight = min(
      min(viewportSize.width, imageRect.right),
      max(original.right + deltaX, original.left + dotSize - 3),
    );
    double newBottom = max(
      min(original.bottom + deltaY, min(viewportSize.height, imageRect.bottom)),
      original.top + dotSize - 3,
    );
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        original.top,
        newRight,
        newBottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = newRight - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = newBottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      }
    }
  }

  /// calculates [ViewportBasedRect] of the result of user moving the left edge.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  ViewportBasedRect moveLeft({
    required ViewportBasedRect original,
    required ViewportBasedRect imageRect,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    double? aspectRatio,
  }) {
    double newLeft = max(
      max(0, imageRect.left),
      min(original.left + deltaX, original.right - dotSize + 3),
    );
    double newTop = min(
      max(original.top + deltaY, max(0, imageRect.top)),
      original.bottom - dotSize + 3,
    );
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        newTop,
        original.right,
        original.bottom,
      );
    } else {
      var newWidth = original.right - newLeft;
      var newHeight = newWidth / aspectRatio;
      if (original.bottom - newHeight < imageRect.top) {
        dev.log("original.bottom - newHeight < imageRect.top");
        newHeight = original.bottom - imageRect.top;
        newWidth = newHeight * aspectRatio;
      }
      var heightDelta = original.height - newHeight;

      return Rect.fromLTRB(
        original.right - newWidth,
        original.bottom - newHeight - heightDelta / 2,
        original.right,
        original.bottom - heightDelta / 2,
      );
    }
  }

  /// calculates [ViewportBasedRect] of the result of user moving the right edge.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  /// * [viewportSize] -> Size of preview and gesture area
  ViewportBasedRect moveRight({
    required ViewportBasedRect original,
    required ViewportBasedRect imageRect,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    required Size viewportSize,
    double? aspectRatio,
  }) {
    final newRight = min(
      min(viewportSize.width, imageRect.right),
      max(original.right + deltaX, original.left + dotSize),
    );
    final newBottom = max(
      min(original.bottom + deltaY, min(viewportSize.height, imageRect.bottom)),
      original.top + dotSize,
    );
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        original.top,
        newRight,
        newBottom,
      );
    } else {
      var newWidth = newRight - original.left;
      var newHeight = newWidth / aspectRatio;
      if (original.top + newHeight > imageRect.bottom) {
        newHeight = imageRect.bottom - original.top;
        newWidth = newHeight * aspectRatio;
      }
      var heightDelta = original.height - newHeight;
      return Rect.fromLTWH(
        original.left,
        original.top + heightDelta / 2,
        newWidth,
        newHeight,
      );
    }
  }

  /// calculates [ViewportBasedRect] of the result of user moving the top edge.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  ViewportBasedRect moveTop({
    required ViewportBasedRect original,
    required ViewportBasedRect imageRect,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    double? aspectRatio,
  }) {
    double newLeft = max(
      max(0, imageRect.left),
      min(original.left + deltaX, original.right - dotSize + 3),
    );
    double newTop = min(
      max(original.top + deltaY, max(0, imageRect.top)),
      original.bottom - dotSize + 3,
    );
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        newTop,
        original.right,
        original.bottom,
      );
    } else {
      var newHeight = original.bottom - newTop;
      var newWidth = newHeight * aspectRatio;
      if (original.left + newWidth > imageRect.right) {
        newWidth = imageRect.right - original.left;
        newHeight = newWidth / aspectRatio;
      }

      var deltaWidth = original.width - newWidth;

      return Rect.fromLTRB(
        original.left + deltaWidth / 2,
        original.bottom - newHeight,
        original.left + newWidth + deltaWidth / 2,
        original.bottom,
      );
    }
  }

  /// calculates [ViewportBasedRect] of the result of user moving the bottom edge.
  /// * [original] -> Crop Size
  /// * [imageRect] -> Image Size
  /// * [dotSize] -> Size of dot
  /// * [aspectRatio] -> Maintain aspect ratio for crop rect
  /// * [viewportSize] -> Size of preview and gesture area
  ViewportBasedRect moveBottom({
    required ViewportBasedRect original,
    required ViewportBasedRect imageRect,
    required double deltaX,
    required double deltaY,
    required double dotSize,
    required Size viewportSize,
    double? aspectRatio,
  }) {
    final newRight = min(
      min(viewportSize.width, imageRect.right),
      max(original.right + deltaX, original.left + dotSize - 3),
    );
    final newBottom = max(
      min(original.bottom + deltaY, min(viewportSize.height, imageRect.bottom)),
      original.top + dotSize - 3,
    );
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        original.top,
        newRight,
        newBottom,
      );
    } else {
      var newHeight = newBottom - original.top;
      var newWidth = newHeight * aspectRatio;
      if (original.left + newWidth > imageRect.right) {
        newWidth = imageRect.right - original.left;
        newHeight = newWidth / aspectRatio;
      }
      var deltaWidth = original.width - newWidth;
      return Rect.fromLTWH(
        original.left + deltaWidth / 2,
        original.top,
        newWidth,
        newHeight,
      );
    }
  }

  /// correct [ViewportBasedRect] not to exceed [ViewportBasedRect] of image.
  ViewportBasedRect correct(
    ViewportBasedRect rect,
    ViewportBasedRect imageRect,
  ) {
    return Rect.fromLTRB(
      max(rect.left, imageRect.left),
      max(rect.top, imageRect.top),
      min(rect.right, imageRect.right),
      min(rect.bottom, imageRect.bottom),
    );
  }
}

class HorizontalCalculator extends Calculator {
  const HorizontalCalculator();

  @override
  ViewportBasedRect imageRect(Size screenSize, double imageRatio) {
    final imageScreenHeight = screenSize.width / imageRatio;
    final top = (screenSize.height - imageScreenHeight) / 2;
    final bottom = top + imageScreenHeight;
    return Rect.fromLTWH(0, top, screenSize.width, bottom - top);
  }

  @override
  ViewportBasedRect initialCropRect(
    Size screenSize,
    ViewportBasedRect imageRect,
    double aspectRatio,
    double sizeRatio,
  ) {
    final imageRatio = imageRect.width / imageRect.height;

    // consider crop area will fit vertically or horizontally to image
    final initialSize = imageRatio > aspectRatio
        ? Size((imageRect.height * aspectRatio) * sizeRatio,
            imageRect.height * sizeRatio)
        : Size(screenSize.width * sizeRatio,
            (screenSize.width / aspectRatio) * sizeRatio);

    return Rect.fromLTWH(
      (screenSize.width - initialSize.width) / 2,
      (screenSize.height - initialSize.height) / 2,
      initialSize.width,
      initialSize.height,
    );
  }

  @override
  double scaleToCover(Size screenSize, ViewportBasedRect imageRect) {
    return screenSize.height / imageRect.height;
  }

  @override
  double screenSizeRatio(ImageDetail targetImage, Size screenSize) {
    return targetImage.width / screenSize.width;
  }
}

class VerticalCalculator extends Calculator {
  const VerticalCalculator();

  @override
  ViewportBasedRect imageRect(Size screenSize, double imageRatio) {
    final imageScreenWidth = screenSize.height * imageRatio;
    final left = (screenSize.width - imageScreenWidth) / 2;
    final right = left + imageScreenWidth;
    return Rect.fromLTWH(left, 0, right - left, screenSize.height);
  }

  @override
  ViewportBasedRect initialCropRect(
    Size screenSize,
    ViewportBasedRect imageRect,
    double aspectRatio,
    double sizeRatio,
  ) {
    final imageRatio = imageRect.width / imageRect.height;

    final initialSize = imageRatio < aspectRatio
        ? Size(imageRect.width * sizeRatio,
            imageRect.width / aspectRatio * sizeRatio)
        : Size((screenSize.height * aspectRatio) * sizeRatio,
            screenSize.height * sizeRatio);

    return Rect.fromLTWH(
      (screenSize.width - initialSize.width) / 2,
      (screenSize.height - initialSize.height) / 2,
      initialSize.width,
      initialSize.height,
    );
  }

  @override
  double scaleToCover(Size screenSize, ViewportBasedRect imageRect) {
    return screenSize.width / imageRect.width;
  }

  @override
  double screenSizeRatio(ImageDetail targetImage, Size screenSize) {
    return targetImage.height / screenSize.height;
  }
}
