import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:crop_image_module/cropping/crop_controller.dart'
    as crop_control;
import 'package:crop_image_module/cropping/crop_image.dart';
import 'package:crop_image_module/cropping/helpers/enums/enums.dart';
import 'package:crop_image_module/cropping/helpers/enums/typedef.dart';
import 'package:crop_image_module/cropping/helpers/extensions/extensions.dart';
import 'package:crop_image_module/cropping/logic/logic.dart';
import 'package:crop_image_module/cropping/logic/shape.dart';
import 'package:crop_image_module/cropping/widget/calculator.dart';
import 'package:crop_image_module/cropping/widget/circle_crop_area_clipper.dart';
import 'package:crop_image_module/cropping/widget/dot_control.dart';
import 'package:crop_image_module/cropping/widget/edge_alignment.dart';
import 'package:crop_image_module/cropping/widget/rect_crop_area_clipper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const dotTotalSize = 32.0; // fixed corner dot size.

/// Widget for the entry point of crop_your_image.
class MinhCrop extends StatelessWidget {
  /// original image data
  final Uint8List image;

  /// callback when cropping completed
  /// [cropImageRect] is the crop Rect in the source image
  /// [cropRect] is the rect in the viewport container
  /// [imageRect] is the imageRect in the viewport container
  final void Function(Rect cropImageRect, Rect cropRect, Rect imageRect)
      onCropRect;

  /// callback when cropping completed
  final ValueChanged<Uint8List> onCropped;

  /// fixed aspect ratio of cropping rect.
  /// null, by default, means no fixed aspect ratio.
  final double? aspectRatio;

  /// initial size of cropping rect.
  /// Set double value less than 1.0.
  /// if initialSize is 1.0 (or null),
  /// cropping area would expand as much as possible.
  final double? initialSize;

  /// Builder for initial [ViewportBasedRect] of cropping rect.
  /// Builder is called when calculating initial cropping rect
  /// with passing [ViewportBasedRect] of viewport and image.
  final CroppingRectBuilder? initialRectBuilder;

  /// Initial [ImageBasedRect] of cropping rect, called "area" in this package.
  ///
  /// Note that [ImageBasedRect] is [Rect] based on original [image] data, not screen.
  ///
  /// e.g. If the original image size is 1280x1024,
  /// giving [Rect.fromLTWH(240, 212, 800, 600)] as [initialArea] would
  /// result in covering exact center of the image with 800x600 image size
  /// regardless of the size of viewport.
  ///
  /// If [initialArea] is given, [initialSize] is ignored.
  /// On the other hand, [aspectRatio] is still enabled although
  /// [initialArea] is given and the initial shape of cropping rect looks ignoring [aspectRatio].
  /// Once user moves cropping rect with their hand,
  /// the shape of cropping area is re-calculated depending on [aspectRatio].
  final ImageBasedRect? initialArea;

  /// flag if cropping image with circle shape.
  /// As oval shape is not supported, [aspectRatio] is fixed to 1 if [withCircleUi] is true.
  final bool withCircleUi;

  /// conroller for control crop actions
  final crop_control.CropController? controller;

  /// Callback called when cropping rect changes for any reasons.
  final ValueChanged<ViewportBasedRect>? onMoved;

  /// Callback called when status of Crop widget is changed.
  ///
  /// note: Currently, the very first callback is [CropStatus.ready]
  /// which is called after loading [image] data for the first time.
  final ValueChanged<CropStatus>? onStatusChanged;

  /// [Color] of the mask widget which is placed over the cropping editor.
  final Color? maskColor;

  /// [Color] of the base color of the cropping editor.
  final Color baseColor;

  /// Corner radius of cropping rect
  final double radius;

  /// Builder function for corner dot widgets.
  /// [CornerDotBuilder] passes [size] which indicates a desired size of each dots
  /// and [EdgeAlignment] which indicates the position of each dot.
  /// If you want default dot widget with different color, [DotControl] is available.
  final CornerDotBuilder? cornerDotBuilder;

  /// [Clip] configuration for crop editor, especially corner dots.
  /// [Clip.hardEdge] by default.
  final Clip clipBehavior;

  /// [Widget] for showing preparing for image is in progress.
  /// [SizedBox.shrink()] is used by default.
  final Widget progressIndicator;

  /// If [true], the cropping editor is changed to _interactive_ mode
  /// and users can zoom and pan the image.
  /// [false] by default.
  final bool interactive;

  /// If [fixCropRect] and [interactive] are both [true], cropping rect is fixed and can't be moved.
  /// [false] by default.
  final bool fixCropRect;

  /// Function called before scaling image.
  /// Note that this function is called multiple times during user tries to scale image.
  /// If this function returns [false], scaling is canceled.
  final WillUpdateScale? willUpdateScale;

  /// (for Web) Sets the mouse-wheel zoom sensitivity for web applications.
  final double scrollZoomSensitivity;

  /// (Advanced) Injected logic for cropping image.
  final ImageCropper imageCropper;

  /// (Advanced) Injected logic for detecting image format.
  final FormatDetector? formatDetector;

  /// (Advanced) Injected logic for parsing image detail.
  final ImageParser imageParser;

  /// Padding horizontal for crop rect after resizing by end of the gesture
  final double? paddingHorizontal;

  /// Padding vertical for crop rect after resizing by end of the gesture
  final double? paddingVertical;

  MinhCrop({
    super.key,
    required this.image,
    required this.onCropped,
    required this.onCropRect,
    this.aspectRatio,
    this.initialSize,
    this.initialRectBuilder,
    this.initialArea,
    this.withCircleUi = false,
    this.controller,
    this.onMoved,
    this.onStatusChanged,
    this.maskColor,
    this.baseColor = Colors.white,
    this.radius = 0,
    this.cornerDotBuilder,
    this.clipBehavior = Clip.hardEdge,
    this.fixCropRect = false,
    this.progressIndicator = const SizedBox.shrink(),
    this.interactive = false,
    this.willUpdateScale,
    this.formatDetector = defaultFormatDetector,
    this.imageCropper = defaultImageCropper,
    ImageParser? imageParser,
    this.scrollZoomSensitivity = 0.05,
    this.paddingHorizontal,
    this.paddingVertical,
  })  : assert((initialSize ?? 1.0) <= 1.0,
            'initialSize must be less than 1.0, or null meaning not specified.'),
        this.imageParser = imageParser ?? defaultImageParser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (c, constraints) {
        final newData = MediaQuery.of(c).copyWith(
          size: constraints.biggest,
        );
        return MediaQuery(
          data: newData,
          child: _CropEditor(
            key: key,
            image: image,
            onCropped: onCropped,
            onCropRect: onCropRect,
            aspectRatio: aspectRatio,
            initialSize: initialSize,
            initialRectBuilder: initialRectBuilder,
            initialArea: initialArea,
            withCircleUi: withCircleUi,
            controller: controller,
            onMoved: onMoved,
            onStatusChanged: onStatusChanged,
            maskColor: maskColor,
            baseColor: baseColor,
            radius: radius,
            cornerDotBuilder: cornerDotBuilder,
            clipBehavior: clipBehavior,
            fixCropRect: fixCropRect,
            progressIndicator: progressIndicator,
            interactive: interactive,
            willUpdateScale: willUpdateScale,
            scrollZoomSensitivity: scrollZoomSensitivity,
            imageCropper: imageCropper,
            formatDetector: formatDetector,
            imageParser: imageParser,
            paddingHorizontal: paddingHorizontal ?? 30,
            paddingVertical: paddingHorizontal ?? 30,
          ),
        );
      },
    );
  }
}

class _CropEditor extends StatefulWidget {
  final Uint8List image;
  final ValueChanged<Uint8List> onCropped;
  final void Function(Rect imageCropRect, Rect cropRect, Rect imageRect)
      onCropRect;
  final double? aspectRatio;
  final double? initialSize;
  final CroppingRectBuilder? initialRectBuilder;
  final ImageBasedRect? initialArea;
  final bool withCircleUi;
  final crop_control.CropController? controller;
  final ValueChanged<ViewportBasedRect>? onMoved;
  final ValueChanged<CropStatus>? onStatusChanged;
  final Color? maskColor;
  final Color baseColor;
  final double radius;
  final CornerDotBuilder? cornerDotBuilder;
  final Clip clipBehavior;
  final bool fixCropRect;
  final Widget progressIndicator;
  final bool interactive;
  final WillUpdateScale? willUpdateScale;
  final ImageCropper imageCropper;
  final FormatDetector? formatDetector;
  final ImageParser imageParser;
  final double scrollZoomSensitivity;
  final double paddingHorizontal;
  final double paddingVertical;

  const _CropEditor({
    super.key,
    required this.image,
    required this.onCropped,
    required this.onCropRect,
    required this.aspectRatio,
    required this.initialSize,
    required this.initialRectBuilder,
    required this.initialArea,
    this.withCircleUi = false,
    required this.controller,
    required this.onMoved,
    required this.onStatusChanged,
    required this.maskColor,
    required this.baseColor,
    required this.radius,
    required this.cornerDotBuilder,
    required this.clipBehavior,
    required this.fixCropRect,
    required this.progressIndicator,
    required this.interactive,
    required this.willUpdateScale,
    required this.imageCropper,
    required this.formatDetector,
    required this.imageParser,
    required this.scrollZoomSensitivity,
    required this.paddingHorizontal,
    required this.paddingVertical,
  });

  @override
  _CropEditorState createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor>
    with TickerProviderStateMixin {
  late crop_control.CropController _cropController;

  /// image with detail info parsed with [widget.imageParser]
  ImageDetail? _parsedImageDetail;

  /// [Size] of viewport
  /// This is equivalent to [MediaQuery.of(context).size]
  late Size _viewportSize;

  /// [ViewportBasedRect] of displaying image
  /// Note that this is not the actual [Size] of the image.
  late ViewportBasedRect _imageRect;

  /// for cropping editor
  double? _aspectRatio;
  bool _withCircleUi = false;
  bool _isFitVertically = false;

  /// [ViewportBasedRect] of cropping area
  /// The result of cropping is based on this [_cropRect].
  late ViewportBasedRect _cropRect;

  bool _showCropAreaOnly = true;

  set showCropAreaOnly(bool value) {
    _showCropAreaOnly = value;
  }

  set cropRect(ViewportBasedRect newRect) {
    setState(() => _cropRect = newRect);
    widget.onMoved?.call(_cropRect);
  }

  var _baseRect = Rect.zero;
  var _baseImageRect = Rect.zero;
  var finalImageRect = Rect.zero;
  Offset _totalDistance = Offset.zero;

  void _endMoveDot(DragEndDetails details) {
    _endPan(details);
    _movingToCenter();
  }

  void _movingToCenter() {
    Size viewPortSizeWithPadding = Size(
        _viewportSize.width - widget.paddingHorizontal * 2,
        _viewportSize.height - widget.paddingVertical * 2);
    double viewportAspectRatio = viewPortSizeWithPadding.aspectRatio;
    double cropRectAspectRatio = _cropRect.size.aspectRatio;
    Size finalCropSize = Size.zero;
    var scaleByWidth = cropRectAspectRatio > viewportAspectRatio;
    if (cropRectAspectRatio > viewportAspectRatio) {
      finalCropSize = Size(viewPortSizeWithPadding.width,
          (viewPortSizeWithPadding.width) / cropRectAspectRatio);
    } else {
      finalCropSize = Size(
          (viewPortSizeWithPadding.height) * cropRectAspectRatio,
          (viewPortSizeWithPadding.height));
    }

    Rect centerCropRect = Rect.fromCenter(
      center: _viewportSize.center(Offset.zero),
      // width: _cropRect.width,
      // height: _cropRect.height,
      width: finalCropSize.width,
      height: finalCropSize.height,
    );
    _baseRect = _cropRect;
    _baseImageRect = _imageRect;
    dev.log("image rect: $_imageRect");
    dev.log("image rect: $_baseRect");
    _totalDistance = centerCropRect.center - _baseRect.center;
    startScale = _scale;
    _cropRectAnimation = RectTween(begin: _baseRect, end: centerCropRect)
        .animate(CurveTween(curve: Curves.decelerate)
            .animate(_toCenterAnimationController));
    _cropRectAnimation.addListener(_animateToCenterListener);
    _toCenterAnimationController.forward(from: 0);
    count += 1;
    showCropAreaOnly = true;
    setState(() {});
  }

  bool get _isImageLoading => _lastComputed != null;

  Calculator get calculator => _isFitVertically
      ? const VerticalCalculator()
      : const HorizontalCalculator();

  ImageFormat? _detectedFormat;

  late final AnimationController _toCenterAnimationController =
      AnimationController(vsync: this, duration: 250.ms);

  late Animation<Rect> _cropRectAnimation;

  @override
  void initState() {
    super.initState();

    _withCircleUi = widget.withCircleUi;

    // prepare for controller
    _cropController = widget.controller ?? crop_control.CropController();
    _cropController.delegate = crop_control.CropControllerDelegate()
      ..onCrop = _crop
      ..onCropRect = _cropTheRect
      ..onChangeAspectRatio = (aspectRatio) {
        dev.log("on change aspect ratio");
        _resizeWith(aspectRatio, null);
      }
      ..onChangeWithCircleUi = (withCircleUi) {
        _withCircleUi = withCircleUi;
        _resizeWith(null, null);
      }
      ..onImageChanged = _resetImage
      ..onChangeCropRect = (newCropRect) {
        cropRect = calculator.correct(newCropRect, _imageRect);
      }
      ..onChangeArea = (newArea) {
        _resizeWith(_aspectRatio, newArea);
      };
  }

  @override
  void didChangeDependencies() {
    _viewportSize = MediaQuery.of(context).size;
    // dev.log("crop didChangeDependencies");
    _parseImageWith(
      parser: widget.imageParser,
      formatDetector: widget.formatDetector,
      image: widget.image,
    );
    super.didChangeDependencies();
  }

  /// reset image to be cropped
  void _resetImage(Uint8List targetImage) {
    widget.onStatusChanged?.call(CropStatus.loading);
    dev.log("_resetImage");
    _parseImageWith(
      parser: widget.imageParser,
      formatDetector: widget.formatDetector,
      image: targetImage,
    );
  }

  /// temporary field to detect last computed.
  ImageParser? _lastParser;
  FormatDetector? _lastFormatDetector;
  Uint8List? _lastImage;
  Future<ImageDetail?>? _lastComputed;

  void _parseImageWith({
    required ImageParser parser,
    required FormatDetector? formatDetector,
    required Uint8List image,
  }) {
    if (_lastParser == parser &&
        _lastImage == image &&
        _lastFormatDetector == formatDetector) {
      // no change
      return;
    }

    _lastParser = parser;
    _lastFormatDetector = formatDetector;
    _lastImage = image;

    final format = formatDetector?.call(image);
    final future = compute(
      _parseFunc,
      [widget.imageParser, format, image],
    );
    _lastComputed = future;
    future.then((parsed) {
      // check if Crop is still alive
      if (!mounted) {
        return;
      }

      // if _parseImageWith() is called again before future completed,
      // just skip and the last future is used.
      if (_lastComputed == future) {
        setState(() {
          _parsedImageDetail = parsed;
          _lastComputed = null;
          _detectedFormat = format;
        });
        _resetCropRect();
        widget.onStatusChanged?.call(CropStatus.ready);
      }
    });
  }

  /// reset [ViewportBasedRect] of crop rect with current state
  void _resetCropRect() {
    final screenSize = _viewportSize;

    final imageAspectRatio =
        _parsedImageDetail!.width / _parsedImageDetail!.height;
    _isFitVertically = imageAspectRatio < screenSize.aspectRatio;

    _imageRect = calculator.imageRect(screenSize, imageAspectRatio);

    if (widget.initialRectBuilder != null) {
      dev.log("_resetCropRect, widget.initialRectBuilder");
      cropRect = widget.initialRectBuilder!(
        Rect.fromLTWH(
          0,
          0,
          screenSize.width,
          screenSize.height,
        ),
        _imageRect,
      );
    } else {
      dev.log(
          "_resetCropRect _resizeWith : ${widget.aspectRatio}, image base initial area ${widget.initialArea}");
      _resizeWith(widget.aspectRatio, widget.initialArea);
      if (widget.initialArea != null) {
        return;
      }
    }

    if (widget.interactive) {
      /// Sẽ scale sao cho ảnh sẽ bị cover về crop Rect. Trước khi gọi scale duới cần set vị trí cropRect trước
      /// Lấy Rect theo _viewportSize vì ảnh ở scale =1 sẽ cover viewport -> scale viewport về cover trong crop rect = scale ảnh về cover trong crop rect
      var initialScale = calculator.scaleToCover(
        _cropRect.size,

        /// Rect ảnh sẽ fit cover
        Rect.fromLTWH(0, 0, _viewportSize.width, _viewportSize.height),

        /// Ảnh
      );
      _applyScale(1 / _scale);
      _applyScale(initialScale);
      dev.log("widget.interactive");
    }
  }

  /// resize crop rect with given aspect ratio and area.
  void _resizeWith(double? aspectRatio, ImageBasedRect? area) {
    dev.log("_resize with $aspectRatio, $area");
    _aspectRatio = _withCircleUi ? 1 : aspectRatio;
    if (area == null) {
      cropRect = calculator.initialCropRect(
        _viewportSize,
        Rect.fromLTWH(0, 0, _viewportSize.width, _viewportSize.height),
        // _imageRect,
        _aspectRatio ?? _parsedImageDetail!.width / _parsedImageDetail!.height,
        widget.initialSize ?? 1,
      );
      var scale = calculator.scaleToCover(_cropRect.size,
          Rect.fromLTWH(0, 0, _viewportSize.width, _viewportSize.height));
      dev.log("init scale: $scale");
      _applyScale(1 / _scale);
      _applyScale(scale);
      dev.log("_resizeWith, scale: ${_scale}");
    } else {
      cropRect = calculator.initialCropRect(
        _viewportSize,
        Rect.fromLTWH(0, 0, _viewportSize.width, _viewportSize.height),
        _aspectRatio ??
            widget.initialArea?.size.aspectRatio ??
            _parsedImageDetail!.width / _parsedImageDetail!.height,
        widget.initialSize ?? 1,
      );
      _imageRect = calculator.imageRect(_viewportSize,
          _parsedImageDetail!.width / _parsedImageDetail!.height);

      ///SCALE ẢNH CHO khop voi crop
      var initialScale = calculator.scaleToCover(
        _cropRect.size,

        /// Rect ảnh sẽ fit cover
        Rect.fromLTWH(0, 0, _viewportSize.width, _viewportSize.height),

        /// Ảnh
      );
      _applyScale(1 / _scale);
      _applyScale(initialScale);

      /// done SCALE ẢNH CHO khop voi crop

      dev.log(
          "image: ${_parsedImageDetail?.width}, ${_parsedImageDetail?.height}");

      double scaleImageCropAreaToImage = _cropRect.width / _cropRect.height >
              _parsedImageDetail!.width / _parsedImageDetail!.height
          ? _parsedImageDetail!.width / area.width
          : _parsedImageDetail!.height / area.height;
      dev.log("scaleImageCropAreaToImage: $scaleImageCropAreaToImage");
      _applyScale(scaleImageCropAreaToImage * _scale);
      var scaleImageToImageRect = _cropRect.width / _cropRect.height >
              _parsedImageDetail!.width / _parsedImageDetail!.height
          ? _parsedImageDetail!.width / _imageRect.width
          : _parsedImageDetail!.height / _imageRect.height;

      var cropTopLeft = area.topLeft / scaleImageToImageRect;

      var offsetTranslation =
          _cropRect.topLeft - cropTopLeft - _imageRect.topLeft;
      _imageRect =
          _imageRect.translate(offsetTranslation.dx, offsetTranslation.dy);

      setState(() {});
      // dev.log("image Rect Scale = $scaleImageToImageRect");
      dev.log("image rect: $_imageRect, scale: $_scale");
      dev.log("crop rect: $_cropRect");
    }
  }

  /// crop given image with given area.
  Future<Uint8List> _crop(bool withCircleShape) async {
    assert(_parsedImageDetail != null);

    final screenSizeRatio = calculator.screenSizeRatio(
      _parsedImageDetail!,
      _viewportSize,
    );

    widget.onStatusChanged?.call(CropStatus.cropping);

    // use compute() not to block UI update
    final cropResult = await compute(
      _cropFunc,
      [
        widget.imageCropper,
        _parsedImageDetail!.image,
        Rect.fromLTWH(
          max((_cropRect.left - _imageRect.left) * screenSizeRatio / _scale,
              0.0),
          max((_cropRect.top - _imageRect.top) * screenSizeRatio / _scale, 0.0),
          _cropRect.width * screenSizeRatio / _scale,
          _cropRect.height * screenSizeRatio / _scale,
        ),
        withCircleShape,
        _detectedFormat,
      ],
    );

    widget.onCropped(cropResult);
    widget.onStatusChanged?.call(CropStatus.ready);
    return cropResult;
  }

  // for zooming
  double _scale = 1.0;
  double _baseScale = 1.0;

  void _startScale(ScaleStartDetails detail) {
    _baseScale = _scale;
    showCropAreaOnly = false;
    setState(() {});
  }

  void _updateScale(ScaleUpdateDetails detail) {
    // move
    var movedLeft = _imageRect.left + detail.focalPointDelta.dx;
    dev.log(
        "_updateScale movedLeft: $movedLeft, ${movedLeft + _imageRect.width}, ${_cropRect.right}");
    if (movedLeft + _imageRect.width < _cropRect.right) {
      movedLeft = _cropRect.right - _imageRect.width;
    }

    var movedTop = _imageRect.top + detail.focalPointDelta.dy;
    if (movedTop + _imageRect.height < _cropRect.bottom) {
      movedTop = _cropRect.bottom - _imageRect.height;
    }
    setState(() {
      _imageRect = ViewportBasedRect.fromLTWH(
        min(_cropRect.left, movedLeft),
        min(_cropRect.top, movedTop),
        _imageRect.width,
        _imageRect.height,
      );
    });

    showCropAreaOnly = false;
    setState(() {});
    _applyScale(
      _baseScale * detail.scale,
      focalPoint: detail.localFocalPoint,
    );
  }

  void _applyScale(
    double nextScale, {
    Offset? focalPoint,
  }) {
    final allowScale = widget.willUpdateScale?.call(nextScale) ?? true;
    if (!allowScale) {
      return;
    }

    late double baseHeight;
    late double baseWidth;
    final ratio = _parsedImageDetail!.height / _parsedImageDetail!.width;

    if (_isFitVertically) {
      baseHeight = _viewportSize.height;
      baseWidth = baseHeight / ratio;
    } else {
      baseWidth = _viewportSize.width;
      baseHeight = baseWidth * ratio;
    }

    // clamp the scale
    nextScale = max(
      nextScale,
      max(_cropRect.width / baseWidth, _cropRect.height / baseHeight),
    );

    if (_scale == nextScale) {
      return;
    }

    // width
    final newWidth = baseWidth * nextScale;
    final horizontalFocalPointBias = focalPoint == null
        ? 0.5
        : (focalPoint.dx - _imageRect.left) / _imageRect.width;
    final leftPositionDelta =
        (newWidth - _imageRect.width) * horizontalFocalPointBias;

    // height
    final newHeight = baseHeight * nextScale;
    final verticalFocalPointBias = focalPoint == null
        ? 0.5
        : (focalPoint.dy - _imageRect.top) / _imageRect.height;
    final topPositionDelta =
        (newHeight - _imageRect.height) * verticalFocalPointBias;

    // position
    final newLeft = max(
        min(_cropRect.left, _imageRect.left - leftPositionDelta),
        _cropRect.right - newWidth);
    final newTop = max(min(_cropRect.top, _imageRect.top - topPositionDelta),
        _cropRect.bottom - newHeight);

    // apply
    setState(() {
      _imageRect = Rect.fromLTRB(
        newLeft,
        newTop,
        newLeft + newWidth,
        newTop + newHeight,
      );
      _scale = nextScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isImageLoading
        ? Center(child: widget.progressIndicator)
        : Stack(
            clipBehavior: widget.clipBehavior,
            children: [
              /// Image
              Listener(
                onPointerSignal: (signal) {
                  if (signal is PointerScrollEvent) {
                    if (signal.scrollDelta.dy > 0) {
                      _applyScale(
                        _scale - widget.scrollZoomSensitivity,
                        focalPoint: signal.localPosition,
                      );
                    } else if (signal.scrollDelta.dy < 0) {
                      _applyScale(
                        _scale + widget.scrollZoomSensitivity,
                        focalPoint: signal.localPosition,
                      );
                    }
                    //print(_scale);
                  }
                },
                child: GestureDetector(
                  onScaleStart: widget.interactive ? _startScale : null,
                  onScaleUpdate: widget.interactive ? _updateScale : null,
                  onScaleEnd: (details) {
                    showCropAreaOnly = true;
                    dev.log("image rect: $_imageRect");
                    setState(() {});
                  },
                  child: Container(
                    color: widget.baseColor,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _imageRect.left,
                          top: _imageRect.top,
                          child: Image.memory(
                            widget.image,
                            width: _isFitVertically
                                ? null
                                : MediaQuery.of(context).size.width * _scale,
                            height: _isFitVertically
                                ? MediaQuery.of(context).size.height * _scale
                                : null,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Mask
              IgnorePointer(
                child: ClipPath(
                  clipper: _withCircleUi
                      ? CircleCropAreaClipper(_cropRect)
                      : CropAreaClipper(_cropRect, widget.radius),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedContainer(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: _showCropAreaOnly
                          ? widget.baseColor
                          : widget.baseColor.withOpacity(0),
                      // color: Colors.transparent,
                    ),
                    duration: 250.ms,
                    curve: Curves.decelerate,
                  ),
                ),
              ),
              if (!widget.interactive && !widget.fixCropRect)
                Positioned(
                  left: _cropRect.left,
                  top: _cropRect.top,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      cropRect = calculator.moveRect(
                        _cropRect,
                        details.delta.dx,
                        details.delta.dy,
                        _imageRect,
                      );
                    },
                    onPanDown: _startPan,
                    onPanEnd: _endPan,
                    onPanCancel: _cancelPan,
                    child: Container(
                      width: _cropRect.width,
                      height: _cropRect.height,
                      color: Colors.transparent,
                    ),
                  ),
                ),

              /// CONTAINER CROP VIEW
              Positioned.fromRect(
                rect: _cropRect,
                child: AnimatedOpacity(
                  opacity: _showCropAreaOnly ? 0 : 1,
                  duration: 300.ms,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 1.66,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fromRect(
                rect: _cropRect.copyWith(
                  left: _cropRect.left + _cropRect.width / 3 - 0.5,
                  width: 1,
                ),
                child: AnimatedOpacity(
                  opacity: _showCropAreaOnly ? 0 : 1,
                  duration: 300.ms,
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: _cropRect.copyWith(
                  left: _cropRect.left + _cropRect.width * 2 / 3 - 0.5,
                  width: 1,
                ),
                child: AnimatedOpacity(
                  opacity: _showCropAreaOnly ? 0 : 1,
                  duration: 300.ms,
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

              Positioned.fromRect(
                rect: _cropRect.copyWith(
                  top: _cropRect.top + _cropRect.height / 3 - 0.5,
                  height: 1,
                ),
                child: AnimatedOpacity(
                  opacity: _showCropAreaOnly ? 0 : 1,
                  duration: 300.ms,
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: _cropRect.copyWith(
                  top: _cropRect.top + _cropRect.height * 2 / 3 - 0.5,
                  height: 1,
                ),
                child: AnimatedOpacity(
                  opacity: _showCropAreaOnly ? 0 : 1,
                  duration: 300.ms,
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

              _leftCropGesture(),
              _rightCropGesture(),
              _topCropGesture(),
              _bottomCropGesture(),

              ///TOP LEFT
              Positioned(
                left: _cropRect.left - (dotTotalSize / 2),
                top: _cropRect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanDown: _startPan,
                  onPanCancel: _cancelPan,
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          showCropAreaOnly = false;
                          cropRect = calculator.moveTopLeft(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  onPanEnd: widget.fixCropRect ? null : _endMoveDot,
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.topLeft) ??
                      const DotControl(),
                ),
              ),

              /// TOP RIGHT
              Positioned(
                left: _cropRect.right - (dotTotalSize / 2),
                top: _cropRect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanDown: _startPan,
                  onPanCancel: _cancelPan,
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          cropRect = calculator.moveTopRight(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  onPanEnd: widget.fixCropRect ? null : _endMoveDot,
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.topRight) ??
                      const DotControl(),
                ),
              ),

              /// BOTTOM LEFT
              Positioned(
                left: _cropRect.left - (dotTotalSize / 2),
                top: _cropRect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanDown: _startPan,
                  onPanCancel: _cancelPan,
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          showCropAreaOnly = false;

                          cropRect = calculator.moveBottomLeft(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  onPanEnd: widget.fixCropRect ? null : _endMoveDot,
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.bottomLeft) ??
                      const DotControl(),
                ),
              ),

              /// BOTTOM RIGHT
              Positioned(
                left: _cropRect.right - (dotTotalSize / 2),
                top: _cropRect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanDown: _startPan,
                  onPanCancel: _cancelPan,
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          showCropAreaOnly = false;
                          cropRect = calculator.moveBottomRight(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  onPanEnd: widget.fixCropRect ? null : _endMoveDot,
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.bottomRight) ??
                      const DotControl(),
                ),
              ),
            ],
          );
  }

  var count = 0;
  double startScale = 1;

  void _animateToCenterListener() {
    var offset = _cropRectAnimation.value.topLeft - _baseRect.topLeft;
    var deltaScale = _cropRectAnimation.value.width / _baseRect.width;
    var deltaScaleDy = _cropRectAnimation.value.height / _baseRect.height;

    ///Dung top left de translate nhung cropRect sau do co the thay doi width + height vi scale ra giua man hinh
    cropRect = _baseRect
        .translate(
          offset.dx,
          offset.dy,
        )
        .copyWith(
          width: _cropRectAnimation.value.width,
          height: _cropRectAnimation.value.height,
        );

    dev.log("delta scale: ${deltaScaleDy - deltaScale}");

    ///Neu crop Di chuyen ve giua + scale thay doi thi topleft thay doi 1 khoang bang offet * scale
    ///Van phai update lai imagerect width va height de image rect sau khi thay doi dung voi scale
    _imageRect = _baseImageRect
        .translate(
          offset.dx * deltaScale,
          offset.dy * deltaScaleDy,
        )
        .copyWith(
          width: _baseImageRect.width * deltaScale,
          height: _baseImageRect.height * deltaScaleDy,
        );
    _scale = startScale * deltaScale;
    // dev.log("image rect: $_baseImageRect-> $_imageRect");
    if (_cropRectAnimation.isCompleted) {
      _cropRectAnimation.removeListener(_animateToCenterListener);
    }
  }

  Rect _cropTheRect() {
    final double screenSizeRatio = calculator.screenSizeRatio(
      _parsedImageDetail!,
      _viewportSize,
    );
    Rect rect = Rect.fromLTWH(
      (_cropRect.left - _imageRect.left) * screenSizeRatio / _scale,
      (_cropRect.top - _imageRect.top) * screenSizeRatio / _scale,
      _cropRect.width * screenSizeRatio / _scale,
      _cropRect.height * screenSizeRatio / _scale,
    );
    rect = rect.intersect(Rect.fromLTWH(
        0.0, 0.0, _parsedImageDetail!.width, _parsedImageDetail!.height));
    widget.onCropRect.call(rect, _cropRect, _imageRect);
    return rect;
  }

  Widget _leftCropGesture() {
    return Positioned.fromRect(
      rect: Rect.fromLTRB(
        _cropRect.left - 10,
        _cropRect.top + 16,
        _cropRect.left + 10,
        _cropRect.bottom - 16,
      ),
      child: GestureDetector(
        onPanUpdate: widget.fixCropRect
            ? null
            : (details) {
                showCropAreaOnly = false;
                cropRect = calculator.moveLeft(
                  _cropRect,
                  details.delta.dx,
                  0,
                  _imageRect,
                  _aspectRatio,
                );
              },
        onPanDown: _startPan,
        onPanCancel: _cancelPan,
        onPanEnd: widget.fixCropRect ? null : _endMoveDot,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _rightCropGesture() {
    return Positioned.fromRect(
      rect: Rect.fromLTRB(
        _cropRect.right - 10,
        _cropRect.top + 16,
        _cropRect.right + 10,
        _cropRect.bottom - 16,
      ),
      child: GestureDetector(
        onPanUpdate: widget.fixCropRect
            ? null
            : (details) {
                showCropAreaOnly = false;
                cropRect = calculator.moveRight(
                  _cropRect,
                  details.delta.dx,
                  0,
                  _imageRect,
                  _aspectRatio,
                );
              },
        onPanDown: _startPan,
        onPanCancel: _cancelPan,
        onPanEnd: widget.fixCropRect ? null : _endMoveDot,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _topCropGesture() {
    return Positioned.fromRect(
      rect: Rect.fromLTRB(
        _cropRect.left + 16,
        _cropRect.top - 10,
        _cropRect.right - 16,
        _cropRect.top + 10,
      ),
      child: GestureDetector(
        onPanUpdate: widget.fixCropRect
            ? null
            : (details) {
                showCropAreaOnly = false;
                cropRect = calculator.moveTop(
                  _cropRect,
                  0,
                  details.delta.dy,
                  _imageRect,
                  _aspectRatio,
                );
              },
        onPanDown: _startPan,
        onPanCancel: _cancelPan,
        onPanEnd: widget.fixCropRect ? null : _endMoveDot,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _bottomCropGesture() {
    return Positioned.fromRect(
      rect: Rect.fromLTRB(
        _cropRect.left + 16,
        _cropRect.bottom - 10,
        _cropRect.right - 16,
        _cropRect.bottom + 10,
      ),
      child: GestureDetector(
        onPanUpdate: widget.fixCropRect
            ? null
            : (details) {
                showCropAreaOnly = false;
                cropRect = calculator.moveBottom(
                  _cropRect,
                  0,
                  details.delta.dy,
                  _imageRect,
                  _aspectRatio,
                );
              },
        onPanDown: _startPan,
        onPanCancel: _cancelPan,
        onPanEnd: widget.fixCropRect ? null : _endMoveDot,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  void _startPan(DragDownDetails details) {
    showCropAreaOnly = false;
    setState(() {});
  }

  void _endPan(DragEndDetails details) {
    showCropAreaOnly = true;
    setState(() {});
  }

  void _cancelPan() {
    showCropAreaOnly = true;
    setState(() {});
  }
}

/// Non-nullable version of ColorTween.
class RectTween extends Tween<Rect> {
  RectTween({required Rect begin, required Rect end})
      : super(begin: begin, end: end);

  @override
  Rect lerp(double t) {
    return Rect.lerp(begin, end, t)!;
  }
}

/// top-level function for [compute]
/// calls [ImageParser.call] with given arguments
ImageDetail _parseFunc(List<dynamic> args) {
  final parser = args[0] as ImageParser;
  final format = args[1] as ImageFormat?;
  return parser(args[2] as Uint8List, inputFormat: format);
}

/// top-level function for [compute]
/// calls [ImageCropper.call] with given arguments
FutureOr<Uint8List> _cropFunc(List<dynamic> args) {
  final cropper = args[0] as ImageCropper;
  final originalImage = args[1];
  final rect = args[2] as Rect;
  final withCircleShape = args[3] as bool;

  // TODO(chooyan-eng): currently always PNG
  // final outputFormat = args[4] as ImageFormat?;

  return cropper.call(
    original: originalImage,
    topLeft: Offset(rect.left, rect.top),
    bottomRight: Offset(rect.right, rect.bottom),
    shape: withCircleShape ? ImageShape.circle : ImageShape.rectangle,
  );
}
