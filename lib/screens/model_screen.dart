import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_app/services/tflite_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:io';

class ModelScreen extends StatefulWidget {
  // TFService es un servicio asincrono para obtener la respesta del modelo
  final TFService tfService;
  const ModelScreen({super.key, required this.tfService});

  @override
  ModelScreenState createState() => ModelScreenState();
}

class ModelScreenState extends State<ModelScreen> {
  List<String> _etiquetas = [];
  String _output = "Presione en Seleccionar Imagen para seleccionar una imagen";
  File? _image;

  var customLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _cargarEtiquetas();
  }

  // Cargar las etiquetas del modelo
  Future<void> _cargarEtiquetas() async {
    final etiquetas = await rootBundle.loadString("assets/models/labels.txt");

    setState(() {
      _etiquetas = etiquetas.split("\n");
    });
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _runModel() async {
    if (_image == null) {
      setState(() {
        _output = 'Por favor, selecciona una imagen primero.';
      });
      return;
    }

    try {
      List<double> result = await widget.tfService.runModel(_image!);

      final int predictedIndex = _argMax(result);
      final String predictedLabel = _etiquetas[predictedIndex];
      final double confidence = result[predictedIndex];

      customLogger.i('Result : $result');
      setState(() {
        //_output = result.toString();
        _output =
            'Predicción: $predictedLabel\nConfianza: ${(confidence * 100).toStringAsFixed(2)}%';
      });
    } catch (e) {
      setState(() {
        _output = 'Error al ejecutar el modelo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Clasificador de imágenes")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? Text("Seleccione primero una imagen")
                  : Image.file(_image!, height: 200),
              SizedBox(height: 50),

              ElevatedButton(onPressed: _pickImage, child: Text("Seleccionar Imagen")),
              SizedBox(height: 50),
              ElevatedButton(onPressed: _runModel, child: Text("Ejecutar Modelo")),
              SizedBox(height: 50),
              Text(_output, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
