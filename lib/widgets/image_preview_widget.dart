import 'package:flutter/material.dart';
import 'dart:io';

class ImagePreviewWidget extends StatelessWidget {
  final File? image;

  const ImagePreviewWidget({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(5),
        color: Colors.grey.shade200,
      ),
      width: 300,
      height: 300,
      child: image != null
          ? Image.file(image!)
          : const Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey),
            ),
    );
  }
}
