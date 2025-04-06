import 'dart:convert';

import 'package:ailytics/pages/final_result_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FeatureSelectionPage extends StatefulWidget {
  final Map<String, dynamic> processedData;
  final String fileName;

  const FeatureSelectionPage({
    Key? key,
    required this.processedData,
    required this.fileName,
  });

  @override
  _FeatureSelectionPageState createState() => _FeatureSelectionPageState();
}

class _FeatureSelectionPageState extends State<FeatureSelectionPage> {
  List<String> features = [];
  // Map to hold each feature's classification: "Expense", "Revenue", or "N/A"
  Map<String, String> featureClassifications = {};

  @override
  void initState() {
    super.initState();
    // Initialize features from the processedData passed via constructor.
    if (widget.processedData['columns'] != null) {
      features = List<String>.from(widget.processedData['columns']);
      // Set a default classification for each feature. (Default is "Expense".)
      for (var feature in features) {
        featureClassifications[feature] = "Expense";
      }
    }
  }

  /// Function to send the cached file along with the feature classifications
  /// to your backend endpoint "/process-final-result".
  Future<Map<String, dynamic>> processFile(String cacheFilename) async {
  try {

    // 🔥 Change this URL based on your environment
    // final Uri apiUrl = Uri.parse("http://10.0.2.2:5000/process-final-result"); // Android Emulator
    final Uri apiUrl = Uri.parse("http://localhost:5000/process-final-result"); // For Windows

    // final Uri apiUrl = Uri.parse("http://localhost:5000/process-final-result"); // iOS Simulator / Web
    // final Uri apiUrl = Uri.parse("http://<YOUR_PC_LOCAL_IP>:5000/process-final-result"); //Physical Device

    // Create a multipart request.
    var request = http.MultipartRequest('POST', apiUrl);

    // Instead of sending the file, add the cache filename as a field.
    // Ensure that widget.processedData['cache_filename'] contains the correct filename.
    request.fields['cache_filename'] = cacheFilename;

    // Add the feature classifications as a field (encoded as JSON).
    request.fields['featureClassifications'] = jsonEncode(featureClassifications);

    // Send the request and await the response.
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Parse JSON response.
    } else {
      throw Exception('Failed to process file: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending file: $e');
    throw e;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feature Selection for \n${widget.fileName}"),
      ),
      body: Column(
        children: [
          // Information section about revenue, profit, and N/A.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Information:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Revenue: Income generated from sales of goods and services.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  "Profit: Revenue minus expenses (costs incurred to generate revenue).",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  "N/A: Not Applicable - this feature will not be used for classification.",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return ListTile(
                  title: Text(feature),
                  trailing: DropdownButton<String>(
                    value: featureClassifications[feature],
                    items: <String>['Expense', 'Revenue', 'N/A']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        featureClassifications[feature] = newValue!;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  // Retrieve the cache filename from processedData.
                  String? cacheFilename = widget.processedData['cache_filename'];
                  if (cacheFilename == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cache filename is missing from processed data.")),
                    );
                    return;
                  }
                  
                  // Call the processFile function to send the file and feature classifications to the backend.
                  Map<String, dynamic> result = await processFile(cacheFilename);
                  
                  // Navigate to FinalResultPage, passing the processed data from the backend.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinalResultPage(
                        featureClassifications: featureClassifications,
                        fileName: widget.fileName,
                        processedData: result,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error processing file: $e")),
                  );
                }
              },
              child: const Text("Confirm Selection"),
            ),
          ),
        ],
      ),
    );
  }
}
