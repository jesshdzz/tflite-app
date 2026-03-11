import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_app/controllers/model_controller.dart';
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
  late final ModelController _controller;

  @override
  void initState() {
    super.initState();
    // Instanciamos el servicio y el controlador
    final tfService = TFService();
    _controller = ModelController(tfService);

    // Inicializamos modelo y etiquetas
    _controller.init();
  }

  @override
  void dispose() {
    _controller.tfService.close(); // Limpiamos la memoria del TFLite
    _controller.dispose();
    super.dispose();
  }

  void _onPickImage(ImageSource source) async {
    try {
      await _controller.pickImage(source);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
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
