import 'package:crop_image_module/cropping/logic/cropper/image_image_cropper.dart';
import 'package:crop_image_module/cropping/logic/format_detector/format_detector.dart';
import 'package:crop_image_module/cropping/logic/parser/image_image_parser.dart';

final defaultImageParser = imageImageParser;

// TODO(chooyan-eng): implement format detector if possible
const FormatDetector? defaultFormatDetector = null;

const defaultImageCropper = ImageImageCropper();
