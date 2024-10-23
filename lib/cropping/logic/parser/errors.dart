import 'package:crop_image_module/cropping/logic/format_detector/format.dart';

class InvalidInputFormatError extends Error {
  final ImageFormat? inputFormat;

  InvalidInputFormatError(this.inputFormat);
}
