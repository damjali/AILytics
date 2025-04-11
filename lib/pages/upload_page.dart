import 'dart:io';
import 'package:ailytics/screens/landing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? fileName;
  File? _selectedFile;
  bool isFilePicked = false; // Tracks if a file is selected
  bool isLoading = false; // Tracks if the file is being processed

  // Function to pick a file
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

  // Function to send the file to the Flask backend
  Future<Map<String, dynamic>> processFile(File file) async {
    try {
      // Change this URL based on your environment
      // final Uri apiUrl = Uri.parse("http://10.0.2.2:5000/process-file"); // Android Emulator
      final Uri apiUrl = Uri.parse("http://localhost:5000/process-file"); // For Windows
      // final Uri apiUrl = Uri.parse("http://localhost:5000/process-file"); // iOS Simulator / Web
      //final Uri apiUrl = Uri.parse("http://192.168.0.151:5000/process-file"); //Physical Device

      // Create a multipart request
      var request = http.MultipartRequest('POST', apiUrl);

      // Add the file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ));

       // Send the request and await response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> processedData = jsonDecode(response.body);
        fileName = processedData['file_name'];
        // Save the processed data in Firestore
        await saveProcessedData(processedData);
        return processedData;
      } else {
        throw Exception('Failed to process file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending file: $e');
      throw e;
    }
  }

  Future<void> saveProcessedData(Map<String, dynamic> processedData) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                    const LandingScreen()));
    }
    
    double revenue = 0.0;
    double expenses = 0.0;
    double profit = 0.0;
    double margin = 0.0;

    final cleanedData = processedData['cleaned_data'] as List<dynamic>;
    if (cleanedData.isNotEmpty) {
        // Try to find financial columns in the data
        final firstRow = cleanedData.first as Map<String, dynamic>;

        // Look for revenue/income column
        for (var key in firstRow.keys) {
          String keyLower = key.toLowerCase();
          if (keyLower.contains('revenue') || keyLower.contains('income') || keyLower.contains('sales')) {
            revenue = _calculateAverage(cleanedData, key);
            break;
          }
        }

        // Look for expenses/cost column
        for (var key in firstRow.keys) {
          String keyLower = key.toLowerCase();
          if (keyLower.contains('expense') || keyLower.contains('cost')) {
            expenses = _calculateAverage(cleanedData, key);
            break;
          }
        }

        // If we couldn't find the columns, try to use the first two numeric columns as a fallback
        if (revenue == 0.0 && expenses == 0.0) {
          List<String> numericColumns = [];
          for (var key in firstRow.keys) {
            if (firstRow[key] is num) {
              numericColumns.add(key);
              if (numericColumns.length >= 2) break;
            }
          }

          if (numericColumns.length >= 1) {
            revenue = _calculateAverage(cleanedData, numericColumns[0]);
            print("revenue: $revenue");
          }

          if (numericColumns.length >= 2) {
            expenses = _calculateAverage(cleanedData, numericColumns[1]);
            print("expenses: $expenses");
          }
        }

        // Calculate profit and margin
        profit = revenue - expenses;
        margin = revenue > 0 ? (profit / revenue) * 100 : 0;
      }

    Map<String, dynamic> finalData = {
      'filename': fileName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'revenue': revenue,
      'expenses': expenses,
      'profit': profit,
      'margin': margin, // Typically represented as a decimal (e.g., 0.6667 for 66.67%)
    };

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('processedFiles')
        .doc(fileName);

    await docRef.set(finalData);

    print("finalData has been saved as : $fileName for user: $uid");
  }

  double _calculateAverage(List<dynamic> data, String columnName) {
    double sum = 0;
    int count = 0;

    for (var item in data) {
      if (item is Map<String, dynamic>) {
        // Make sure we handle both numeric values and string representations of numbers
        if (item.containsKey(columnName)) {
          var value = item[columnName];
          if (value is num) {
            sum += value.toDouble();
            count++;
          } else if (value is String) {
            // Try to parse the string as a number
            try {
              sum += double.parse(value);
              count++;
            } catch (_) {
              // Not a number, ignore
            }
          }
        }
      }
    }

    return count > 0 ? sum / count : 0;
  }

  // Function to analyze the report
  void analyzeReport() async {
    if (_selectedFile != null && fileName != null) {
      setState(() {
        isLoading = true; // Show loading indicator
      });

      try {
        // Send the file to the backend and get the processed data
        Map<String, dynamic> result = await processFile(_selectedFile!);

        // Navigate to DataResultPage with the processed data and file name
        Navigator.pushNamed(
          context,
          '/dataResult',
          arguments: {
            'processedData': result,
            'fileName': fileName!,
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing file: $e")),
        );
      } finally {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Data'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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
              onPressed: isFilePicked && !isLoading ? analyzeReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFilePicked && !isLoading ? Colors.black : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Analyze Report"),
            ),
          ],
        ),
      ),
    );
  }
}