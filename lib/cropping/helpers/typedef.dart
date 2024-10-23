import 'package:crop_image_module/cropping/widget/edge_alignment.dart';
import 'package:flutter/material.dart';

typedef ViewportBasedRect = Rect;
typedef ImageBasedRect = Rect;

typedef WillUpdateScale = bool Function(double newScale);
typedef CornerDotBuilder = Widget Function(
    double size, EdgeAlignment edgeAlignment);

typedef CroppingRectBuilder = ViewportBasedRect Function(
  ViewportBasedRect viewportRect,
  ViewportBasedRect imageRect,
);
