import 'dart:math';
import 'package:flutter/material.dart';
import 'package:matrix4_transform/matrix4_transform.dart';

enum EnumCropStatus { nothing, loading, ready, cropping }

enum EnumResizeOrientation {
  normal,
  flipHorizontal,
  rotate180,
  flipVertical,
  transpose,
  rotate90,
  transverse,
  rotate270,
}

class ExifStateMachine {
  final int uid = Random().nextInt(1000);
  final EnumResizeOrientation currentResizeOrientation;
  final Matrix4 matrixExif;

  ExifStateMachine({
    required this.currentResizeOrientation,
    required this.matrixExif,
  });

  bool get isNormal => currentResizeOrientation == EnumResizeOrientation.normal;

  static ExifStateMachine create() {
    return ExifStateMachine(
      currentResizeOrientation: EnumResizeOrientation.normal,
      matrixExif: Matrix4.identity(),
    );
  }

  ExifStateMachine rotate90Clockwise({Offset origin = Offset.zero}) {
    EnumResizeOrientation newState;
    switch (currentResizeOrientation) {
      case EnumResizeOrientation.normal:
        newState = EnumResizeOrientation.rotate90;
        break;
      case EnumResizeOrientation.rotate90:
        newState = EnumResizeOrientation.rotate180;
        break;
      case EnumResizeOrientation.rotate180:
        newState = EnumResizeOrientation.rotate270;
        break;
      case EnumResizeOrientation.rotate270:
        newState = EnumResizeOrientation.normal;
        break;
      case EnumResizeOrientation.flipHorizontal:
        newState = EnumResizeOrientation.transverse;
        break;
      case EnumResizeOrientation.transverse:
        newState = EnumResizeOrientation.flipVertical;
        break;
      case EnumResizeOrientation.flipVertical:
        newState = EnumResizeOrientation.transpose;
        break;
      case EnumResizeOrientation.transpose:
        newState = EnumResizeOrientation.flipHorizontal;
        break;
      default:
        newState = EnumResizeOrientation.normal;
        break;
    }
    return ExifStateMachine(
      currentResizeOrientation: newState,
      matrixExif: newState.getTransformByCenter(origin: origin),
    );
  }

  ExifStateMachine rotate90CounterClockwise({Offset origin = Offset.zero}) {
    EnumResizeOrientation newState;

    switch (currentResizeOrientation) {
      case EnumResizeOrientation.normal:
        newState = EnumResizeOrientation.rotate270;
        break;
      case EnumResizeOrientation.rotate270:
        newState = EnumResizeOrientation.rotate180;
        break;
      case EnumResizeOrientation.rotate180:
        newState = EnumResizeOrientation.rotate90;
        break;
      case EnumResizeOrientation.rotate90:
        newState = EnumResizeOrientation.normal;
        break;
      case EnumResizeOrientation.flipHorizontal:
        newState = EnumResizeOrientation.transpose;
        break;
      case EnumResizeOrientation.transpose:
        newState = EnumResizeOrientation.flipVertical;
        break;
      case EnumResizeOrientation.flipVertical:
        newState = EnumResizeOrientation.transverse;
        break;
      case EnumResizeOrientation.transverse:
        newState = EnumResizeOrientation.flipHorizontal;
        break;
      default:
        newState = EnumResizeOrientation.normal;
        break;
    }
    return ExifStateMachine(
      currentResizeOrientation: newState,
      matrixExif: newState.getTransformByCenter(origin: origin),
    );
  }

  ExifStateMachine flipHorizontal({Offset origin = Offset.zero}) {
    EnumResizeOrientation newState;
    switch (currentResizeOrientation) {
      case EnumResizeOrientation.normal:
        newState = EnumResizeOrientation.flipHorizontal;
        break;
      case EnumResizeOrientation.flipHorizontal:
        newState = EnumResizeOrientation.normal;
        break;
      case EnumResizeOrientation.rotate180:
        newState = EnumResizeOrientation.flipVertical;
        break;
      case EnumResizeOrientation.flipVertical:
        newState = EnumResizeOrientation.rotate180;
        break;
      case EnumResizeOrientation.rotate90:
        newState = EnumResizeOrientation.transpose;
        break;
      case EnumResizeOrientation.transpose:
        newState = EnumResizeOrientation.rotate90;
        break;
      case EnumResizeOrientation.transverse:
        newState = EnumResizeOrientation.rotate270;
        break;
      case EnumResizeOrientation.rotate270:
        newState = EnumResizeOrientation.transverse;
        break;
      default:
        newState = EnumResizeOrientation.normal;
        break;
    }
    return ExifStateMachine(
      currentResizeOrientation: newState,
      matrixExif: newState.getTransformByCenter(origin: origin),
    );
  }

  ExifStateMachine flipVertical({Offset origin = Offset.zero}) {
    EnumResizeOrientation newState;
    switch (currentResizeOrientation) {
      case EnumResizeOrientation.normal:
        newState = EnumResizeOrientation.flipVertical;
        break;
      case EnumResizeOrientation.flipVertical:
        newState = EnumResizeOrientation.normal;
        break;
      case EnumResizeOrientation.rotate180:
        newState = EnumResizeOrientation.flipHorizontal;
        break;
      case EnumResizeOrientation.flipHorizontal:
        newState = EnumResizeOrientation.rotate180;
        break;
      case EnumResizeOrientation.rotate90:
        newState = EnumResizeOrientation.transverse;
        break;
      case EnumResizeOrientation.transpose:
        newState = EnumResizeOrientation.rotate270;
        break;
      case EnumResizeOrientation.rotate270:
        newState = EnumResizeOrientation.transpose;
        break;
      case EnumResizeOrientation.transverse:
        newState = EnumResizeOrientation.rotate90;
        break;
      default:
        newState = EnumResizeOrientation.normal;
        break;
    }
    return ExifStateMachine(
      currentResizeOrientation: newState,
      matrixExif: newState.getTransformByCenter(origin: origin),
    );
  }

  ExifStateMachine reverseExifToReturnNormal({Offset origin = Offset.zero}) {
    EnumResizeOrientation newState;
    switch (currentResizeOrientation) {
      case EnumResizeOrientation.normal:
        newState = EnumResizeOrientation.normal;
        break;
      case EnumResizeOrientation.flipVertical:
        newState = EnumResizeOrientation.flipVertical;
        break;
      case EnumResizeOrientation.rotate180:
        newState = EnumResizeOrientation.rotate180;
        break;
      case EnumResizeOrientation.flipHorizontal:
        newState = EnumResizeOrientation.flipHorizontal;
        break;
      case EnumResizeOrientation.rotate90:
        newState = EnumResizeOrientation.rotate270;
        break;
      case EnumResizeOrientation.transpose:
        newState = EnumResizeOrientation.transpose;
        break;
      case EnumResizeOrientation.rotate270:
        newState = EnumResizeOrientation.rotate90;
        break;
      case EnumResizeOrientation.transverse:
        newState = EnumResizeOrientation.transverse;
        break;
      default:
        newState = EnumResizeOrientation.normal;
        break;
    }
    return ExifStateMachine(
      currentResizeOrientation: newState,
      matrixExif: newState.getTransformByCenter(origin: origin),
    );
  }

  // Matrix4 getTransformByCenter(
  //   EnumResizeOrientation orientation, {
  //   Offset origin = Offset.zero,
  // }) {
  //   Matrix4Transform matrix4transform = Matrix4Transform();
  //   double rotate = 0, flipHorizontal = 1, flipVertical = 1;
  //   switch (orientation) {
  //     case EnumResizeOrientation.normal:
  //       rotate = 0;
  //       break;
  //     case EnumResizeOrientation.rotate90:
  //       rotate = 90;
  //       break;
  //     case EnumResizeOrientation.rotate180:
  //       rotate = 180;
  //       break;
  //     case EnumResizeOrientation.rotate270:
  //       rotate = 270;
  //       break;
  //     case EnumResizeOrientation.flipHorizontal:
  //       flipHorizontal = -1;
  //       break;
  //     case EnumResizeOrientation.flipVertical:
  //       flipVertical = -1;
  //       break;
  //     case EnumResizeOrientation.transpose:
  //       rotate = 90;
  //       flipVertical = -1;
  //       break;
  //     case EnumResizeOrientation.transverse:
  //       rotate = 90;
  //       flipHorizontal = -1;
  //       break;
  //   }
  //   matrix4transform =
  //       matrix4transform.rotate(rotate / 180 * pi, origin: origin);
  //   if (flipHorizontal == -1) {
  //     matrix4transform = matrix4transform.flipHorizontally(origin: origin);
  //   }
  //   if (flipVertical == -1) {
  //     matrix4transform = matrix4transform.flipVertically(origin: origin);
  //   }
  //   return matrix4transform.m;
  // }

  @override
  String toString() {
    return 'Current EnumResizeOrientation: $currentResizeOrientation';
  }
}

extension RotateflipHorizontalflipVertical on EnumResizeOrientation {
  Matrix4 getTransformByCenter({
    Offset origin = Offset.zero,
  }) {
    Matrix4Transform matrix4transform = Matrix4Transform();
    double rotate = 0, flipHorizontal = 1, flipVertical = 1;
    switch (this) {
      case EnumResizeOrientation.normal:
        rotate = 0;
        break;
      case EnumResizeOrientation.rotate90:
        rotate = 90;
        break;
      case EnumResizeOrientation.rotate180:
        rotate = 180;
        break;
      case EnumResizeOrientation.rotate270:
        rotate = 270;
        break;
      case EnumResizeOrientation.flipHorizontal:
        flipHorizontal = -1;
        break;
      case EnumResizeOrientation.flipVertical:
        flipVertical = -1;
        break;
      case EnumResizeOrientation.transpose:
        rotate = 90;
        flipVertical = -1;
        break;
      case EnumResizeOrientation.transverse:
        rotate = 90;
        flipHorizontal = -1;
        break;
    }
    matrix4transform =
        matrix4transform.rotate(rotate / 180 * pi, origin: origin);
    if (flipHorizontal == -1) {
      matrix4transform = matrix4transform.flipHorizontally(origin: origin);
    }
    if (flipVertical == -1) {
      matrix4transform = matrix4transform.flipVertically(origin: origin);
    }
    return matrix4transform.m;
  }

  List<double> getTransform() {
    double rotate = 0, flipHorizontal = 1, flipVertical = 1;
    switch (this) {
      case EnumResizeOrientation.normal:
        rotate = 0;
        flipHorizontal = 1;
        flipVertical = 1;
        break;
      case EnumResizeOrientation.rotate90:
        rotate = 90;
        flipHorizontal = 1;
        flipVertical = 1;
        break;
      case EnumResizeOrientation.rotate180:
        rotate = 180;
        flipHorizontal = 1;
        flipVertical = 1;
        break;
      case EnumResizeOrientation.rotate270:
        rotate = 270;
        flipHorizontal = 1;
        flipVertical = 1;
        break;
      case EnumResizeOrientation.flipHorizontal:
        rotate = 0;
        flipHorizontal = -1;
        flipVertical = 1;
        break;
      case EnumResizeOrientation.flipVertical:
        rotate = 0;
        flipHorizontal = 1;
        flipVertical = -1;
        break;
      case EnumResizeOrientation.transpose:
        rotate = 90;
        flipVertical = -1;
        break;
      case EnumResizeOrientation.transverse:
        rotate = 90;
        flipHorizontal = -1;
        break;
    }
    return [rotate, flipHorizontal, flipVertical];
  }
}
