import 'package:crop_image_module/a_test/format_v2.dart';
import 'dart:ui' as ui;
/// Interface for detecting image format from given [data].
typedef FormatDetectorV2 = ImageFormatV2 Function(ui.Image data);
