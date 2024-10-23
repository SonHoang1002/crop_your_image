import 'package:crop_image_module/cropping/helpers/enums/typedef.dart';

extension ViewportBasedRectExtension on ViewportBasedRect {
  ViewportBasedRect copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return ViewportBasedRect.fromLTWH(
      left ?? this.left,
      top ?? this.top,
      width ?? this.width,
      height ?? this.height,
    );
  }
}

extension NumDurationExtensions on num {
  Duration get um => Duration(microseconds: round());

  Duration get ms => (this * 1000).um;

  Duration get seconds => (this * 1000 * 1000).um;

  Duration get minutes => (this * 1000 * 1000 * 60).um;

  Duration get hours => (this * 1000 * 1000 * 60 * 60).um;

  Duration get days => (this * 1000 * 1000 * 60 * 60 * 24).um;
}
