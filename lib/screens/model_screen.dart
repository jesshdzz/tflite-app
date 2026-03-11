import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_app/services/tflite_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:io';

class ModelScreen extends StatefulWidget {
  const ModelScreen({super.key});

  @override
  ModelScreenState createState() => ModelScreenState();
}

class ModelScreenState extends State<ModelScreen> {
  final TFService tfService = TFService();

  List<String> _etiquetas = [];
  String _output = "";
  File? _image;
  bool _isEnabled = false;
  bool _isLoading = false;
  double _confidence = 0.0;

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
    _cargarModelo();
  }

  Future<void> _cargarModelo() async {
    await tfService.loadModel();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isEnabled = true;
          _output = "";
          _confidence = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al acceder a la cámara/galeria: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _runModel() async {
    if (_image == null) {
      setState(() {
        _output = 'Por favor, selecciona una imagen primero.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<double> result = await tfService.runModel(_image!);

      final int predictedIndex = _argMax(result);

      if (predictedIndex >= _etiquetas.length) {
        setState(() {
          _output = 'Error al ejecutar el modelo: Indice $predictedIndex fuera de rango';
          _isEnabled = true;
          _isLoading = false;
        });
        return;
      }

      final String predictedLabel = _etiquetas[predictedIndex];
      final double confidence = result[predictedIndex];

      customLogger.i('Result : $result');
      setState(() {
        //_output = result.toString();
        _output = 'Predicción: $predictedLabel';
        _confidence = (confidence * 100);
      });
    } catch (e) {
      setState(() {
        _output = 'Error al ejecutar el modelo: $e';
      });
    }

    setState(() {
      _isLoading = false;
      _isEnabled = false;
    });
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
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Primero seleccione una imagen, luego presione Ejecutar Modelo",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey.shade200,
                ),
                width: 300,
                height: 300,
                child: _image != null
                    ? Image.file(_image!)
                    : Center(child: Icon(Icons.image, size: 100, color: Colors.grey)),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt),
                    label: Text("Foto"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.image),
                    label: Text("Imagen"),
                  ),
                ],
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _isEnabled && !_isLoading ? _runModel : null,
                child: Text("Ejecutar Modelo"),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : _output.isEmpty
                  ? SizedBox()
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _output,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            LinearProgressIndicator(value: _confidence / 100),
                            SizedBox(height: 5),
                            Text(
                              "Confianza: ${_confidence.toStringAsFixed(2)}%",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
