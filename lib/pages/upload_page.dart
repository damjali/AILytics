import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? fileName;
  File? _selectedFile;
  bool isFilePicked = false; // Tracks if a file is selected

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        fileName = result.files.single.name;
        _selectedFile = File(result.files.single.path!);
        isFilePicked = true; // Enable Analyze Report button immediately
      });
    }
  }

//Part lepas tekan analyze report, to interact with the file, we use the _selectedFile variable
  void analyzeReport() {
    if (_selectedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Analyzing report: $fileName")),
      );
      //contoh, to print file path, kita use this (will output inside terminal)
      print(_selectedFile!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Your Data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a file to upload and analyze',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload, size: 48, color: Colors.black54),
                    const SizedBox(height: 16),
                    const Text(
                      'Drag & Drop Files Here',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported formats: CSV, XLSX, PDF',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Browse Files'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: const Size(150, 45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // File Name Preview
            if (fileName != null)
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fileName!,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            
            // Analyze Report Button
            ElevatedButton(
              onPressed: isFilePicked ? analyzeReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFilePicked ? Colors.black : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Analyze Report"),
            ),
          ],
        ),
      ),
    );
  }
}
