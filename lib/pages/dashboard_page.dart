// lib/pages/dashboard_page.dart

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ailytics/navigation/app_navigation.dart';
import 'package:http/http.dart' as http;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
      // 🔥 Change this URL based on your environment
      // final Uri apiUrl = Uri.parse("http://10.0.2.2:5000/process-selections"); // Android Emulator
      final Uri apiUrl = Uri.parse("http://localhost:5000/process-selections"); // For Windows

      // final Uri apiUrl = Uri.parse("http://localhost:5000/process-selections"); // iOS Simulator / Web
      // final Uri apiUrl = Uri.parse("http://<YOUR_PC_LOCAL_IP>:5000/process-selections"); //Physical Device

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
        return jsonDecode(response.body); // Parse JSON response
      } else {
        throw Exception('Failed to process file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending file: $e');
      throw e;
    }
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

        // Navigate to FeatureSelectionPage with the processed data and file name
        Navigator.pushNamed(
          context,
          '/featureSelection',
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Implement refresh functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Analytics Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Overview of your business performance',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Revenue',
                    '\$0.00',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Expenses',
                    '\$0.00',
                    Icons.money_off,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Profit',
                    '\$0.00',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Margin',
                    '0%',
                    Icons.pie_chart,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Performance Charts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload data to see visualizations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: const Size(150, 45)
                      )
                    ),
                    const SizedBox(height: 20),

                    // File Name Preview
                    if (fileName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          fileName!,
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),

                      //Analyze Report Button
                      ElevatedButton(
                        onPressed: isFilePicked && !isLoading ? analyzeReport: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFilePicked && !isLoading ? Colors.black : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Analyze Report"),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}