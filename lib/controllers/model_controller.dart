import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_app/services/tflite_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

class ModelController extends ChangeNotifier {
  final TFService tfService;

  List<String> _etiquetas = [];
  String _output = "";
  File? _image;
  bool _isEnabled = false;
  bool _isLoading = false;
  double _confidence = 0.0;

  ModelController(this.tfService);

  // Getters para que la vista lea el estado
  String get output => _output;
  File? get image => _image;
  bool get isEnabled => _isEnabled;
  bool get isLoading => _isLoading;
  double get confidence => _confidence;

  Future<void> init() async {
    await _cargarEtiquetas();
    await _cargarModelo();
  }

  Future<void> _cargarModelo() async {
    await tfService.loadModel();
  }

  Future<void> _cargarEtiquetas() async {
    final etiquetas = await rootBundle.loadString("assets/models/labels.txt");
    _etiquetas = etiquetas.split("\n");
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _isEnabled = true;
        _output = "";
        _confidence = 0.0;
        notifyListeners(); // Notifica a la UI para que se redibuje
      }
    } catch (e) {
      throw Exception("Error al acceder a la cámara/galería: $e");
    }
  }

  int _argMax(List<double> values) {
    int maxIndex = 0;
    double maxValue = values[0];

    for (var i = 0; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  Future<void> runModel() async {
    if (_image == null) {
      _output = 'Por favor, selecciona una imagen primero.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      List<double> result = await tfService.runModel(_image!);
      final int predictedIndex = _argMax(result);

      if (predictedIndex >= _etiquetas.length) {
        _output =
            'Error al ejecutar el modelo: Índice $predictedIndex fuera de rango';
        _isEnabled = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final String predictedLabel = _etiquetas[predictedIndex];
      final double resultConfidence = result[predictedIndex];

      _output = 'Predicción: $predictedLabel';
      _confidence = (resultConfidence * 100);
    } catch (e) {
      _output = 'Error al ejecutar el modelo: $e';
    }

    _isLoading = false;
    _isEnabled = false;
    notifyListeners();
  }
}
