import 'package:flutter/material.dart';

class DataResultPage extends StatelessWidget {
  final Map<String, dynamic> processedData; // Processed data from backend
  final String fileName; // Name of the uploaded file

  const DataResultPage({
    super.key,
    required this.processedData,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Cleaning Results')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Name: $fileName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Cleaning Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '✅ Data Cleaning Completed!',
              style: TextStyle(fontSize: 18, color: Colors.green[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Total rows processed: ${processedData["cleaning_summary"]["total_rows_processed"]}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Duplicate rows removed: ${processedData["cleaning_summary"]["duplicate_rows_removed"]}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Missing values filled: ${processedData["cleaning_summary"]["missing_values_filled"]}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Column names standardized: ${processedData["cleaning_summary"]["column_names_standardized"] ? "Yes" : "No"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cleaned Data Preview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: processedData["cleaned_data"].length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Row ${index + 1}"),
                    subtitle: Text(processedData["cleaned_data"][index].toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}