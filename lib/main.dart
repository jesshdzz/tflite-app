import 'package:flutter/material.dart';
import 'package:tflite_app/screens/model_screen.dart';
import 'package:tflite_app/services/tflite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tfService = TFService();
  await tfService.loadModel();

  runApp(MyApp(tfService: tfService));
}

class MyApp extends StatelessWidget {
  final TFService tfService;
  const MyApp({super.key, required this.tfService});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clasificador de Imagenes con TFLite',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: .fromSeed(seedColor: Colors.blue),
      ),
      home: ModelScreen(tfService: tfService),
      debugShowCheckedModeBanner: false,
    );
  }
}
