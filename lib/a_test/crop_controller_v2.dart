import 'package:crop_image_module/cropping/helpers/typedef.dart';
import 'package:flutter/widgets.dart'; 
import 'dart:ui' as ui;

/// Controller to control crop actions.
class CropControllerV2 {
  late CropControllerDelegateV2 _delegate;

  /// setter for [CropControllerDelegateV2]
  set delegate(CropControllerDelegateV2 value) => _delegate = value;

  /// crop given image with current configuration
  Future<ui.Image> crop() => _delegate.onCrop(false);
  Rect cropTheRect() => _delegate.onCropRect();

  /// crop given image with current configuration and circle shape.
  Future<ui.Image> cropCircle() => _delegate.onCrop(true);

  /// Change image to be cropped.
  /// When image is changed, [Rect] of cropping area will be reset.
  set image(ui.Image value) => _delegate.onImageChanged(value);

  /// change fixed aspect ratio
  /// if [value] is null, cropping area can be moved without fixed aspect ratio.
  set aspectRatio(double? value) => _delegate.onChangeAspectRatio(value);

  /// change if cropping with circle shaped UI.
  /// if [value] is true, [aspectRatio] automatically fixed with 1
  set withCircleUi(bool value) => _delegate.onChangeWithCircleUi(value);

  /// change [ViewportBasedRect] of crop rect.
  /// the value is corrected if it indicates outside of the image.
  set cropRect(ViewportBasedRect value) => _delegate.onChangeCropRect(value);

  /// change [ViewportBasedRect] of crop rect
  /// based on [ImageBasedRect] of original image.
  set area(ImageBasedRect value) => _delegate.onChangeArea(value);
}

/// Delegate of actions from [CropControllerV2]
class CropControllerDelegateV2 {
  /// callback that [CropControllerV2.crop] is called.
  /// the meaning of the value is if cropping a image with circle shape.
  late Future<ui.Image> Function(bool value) onCrop;
  late Rect Function() onCropRect;

  /// callback that [CropControllerV2.image] is set.
  late ValueChanged<ui.Image> onImageChanged;

  /// callback that [CropControllerV2.aspectRatio] is set.
  late ValueChanged<double?> onChangeAspectRatio;

  /// callback that [CropControllerV2.withCircleUi] is changed.
  late ValueChanged<bool> onChangeWithCircleUi;

  /// callback that [CropControllerV2.cropRect] is changed.
  late ValueChanged<ViewportBasedRect> onChangeCropRect;

  /// callback that [CropControllerV2.area] is changed.
  late ValueChanged<ImageBasedRect> onChangeArea;
}
