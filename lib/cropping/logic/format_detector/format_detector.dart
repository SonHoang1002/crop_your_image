import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_image_module/cropping/logic/format_detector/format.dart';

/// Interface for detecting image format from given [data].
typedef FormatDetector = ImageFormat Function(Uint8List data);

typedef FormatDetectorV2 = ImageFormatV2 Function(Image data);