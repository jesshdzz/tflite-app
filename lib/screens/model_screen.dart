import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_app/services/tflite_service.dart';
import 'package:tflite_app/widgets/image_preview_widget.dart';
import 'package:tflite_app/widgets/result_card_widget.dart';
import 'package:tflite_app/widgets/action_buttons_widget.dart';

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
      appBar: AppBar(title: const Text("Clasificador de imágenes")),
      body: SingleChildScrollView(
        child: Center(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (BuildContext context, Widget? child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_controller.image == null)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Primero seleccione una imagen, luego presione Ejecutar Modelo",
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    const SizedBox(height: 20),

                  ImagePreviewWidget(image: _controller.image),

                  const SizedBox(height: 15),
                  ActionButtonsWidget(
                    onCameraPressed: () => _onPickImage(ImageSource.camera),
                    onGalleryPressed: () => _onPickImage(ImageSource.gallery),
                  ),

                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: _controller.isEnabled && !_controller.isLoading
                        ? _controller.runModel
                        : null,
                    child: const Text("Ejecutar Modelo"),
                  ),

                  const SizedBox(height: 20),
                  if (_controller.isLoading)
                    const CircularProgressIndicator()
                  else if (_controller.output.isNotEmpty)
                    ResultCardWidget(
                      output: _controller.output,
                      confidence: _controller.confidence,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
