import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  _FileUploadPageState createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  String? fileName;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        fileName = result.files.single.name;
      });
    }
  }

  void analyzeReport() {
    if (fileName != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Analyzing report: $fileName")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Centers content
            crossAxisAlignment: CrossAxisAlignment.center, // Aligns text to center
            children: [
              const Text(
                "Attach A File",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Attach Your Monthly Report\n(.csv / .pdf / .xlsx / .docx)",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center, // Center text alignment
              ),
              const SizedBox(height: 30),

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
                    textAlign: TextAlign.center, // Center file name
                  ),
                ),
              const SizedBox(height: 20),

              // Attach File Button
              ElevatedButton(
                onPressed: pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Black button
                  foregroundColor: Colors.white, // White text
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Attach File"),
              ),

              const SizedBox(height: 10),

              // Analyze Report Button (Initially Disabled)
              ElevatedButton(
                onPressed: fileName != null ? analyzeReport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: fileName != null ? Colors.black : Colors.grey, // Greyed out when disabled
                  foregroundColor: Colors.white, // White text
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Analyze Report"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
