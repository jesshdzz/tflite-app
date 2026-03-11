import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'dart:io';

class TFService {
  Interpreter? _interpreter;

  var customLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // number of method calls to be displayed
      errorMethodCount: 8, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
    ),
  );

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet_v1_1.0_224.tflite',
      );
      customLogger.i('Model was loaded successfully');
      if (_interpreter != null) {
        var inputShape = _interpreter!.getInputTensor(0).shape;
        var outputShape = _interpreter!.getOutputTensor(0).shape;
        customLogger.i('Input shape: $inputShape');
        customLogger.i('Output shape: $outputShape');
        customLogger.i('Interpreter address: ${_interpreter.hashCode}');
      }
    } catch (e) {
      customLogger.i('Error loading model: $e');
    }
  }

  Future<List<double>> runModel(File imageFile) async {
    if (_interpreter == null) {
      customLogger.e('Interpreter is not initialized. Call loadModel() first.');
      // listado vacío en caso de error
      return [];
    }

    var input = await compute(_preprocesarImagen, imageFile.path);
    var output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);
    
    try {
      _interpreter!.run(input, output);
      customLogger.i('Model inference completed successfully $output');
      //return List<double>.from(output.reshape([1001]));
      return output[0];
    } catch (e) {
      customLogger.e('Error during model inference: $e');
      return [];
    }
  }

  void close() {
    _interpreter?.close();
    customLogger.i('Interpreter closed');
  }
}

List _preprocesarImagen(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  img.Image? imageInput = img.decodeImage(bytes)!;
  img.Image resizedImage = img.copyResize(imageInput, width: 224, height: 224);

  var input = List.generate(1 * 224 * 224 * 3, (index) => 0.0).reshape([1, 224, 224, 3]);

  for (var y = 0; y < resizedImage.height; y++) {
    for (var x = 0; x < resizedImage.width; x++) {
      var pixel = resizedImage.getPixel(x, y);
      // obtener los valores RGB y normalizarlos entre 0 y 1
      input[0][y][x][0] = pixel.r / 255.0; // 0.15
      input[0][y][x][1] = pixel.g / 255.0;
      input[0][y][x][2] = pixel.b / 255.0;
    }
  }

  return input;
}
