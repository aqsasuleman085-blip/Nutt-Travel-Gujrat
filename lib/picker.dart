import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScreenshotPicker extends StatefulWidget {
  @override
  State<ScreenshotPicker> createState() => _ScreenshotPickerState();
}

class _ScreenshotPickerState extends State<ScreenshotPicker> {
  XFile? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[200],
        child: _image == null
            ? Center(child: Text("Tap to upload"))
            : kIsWeb
            ? Image.network(
                _image!.path, // ✅ Web uses network
                fit: BoxFit.cover,
              )
            : Image.file(
                File(_image!.path), // ✅ Mobile uses file
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
