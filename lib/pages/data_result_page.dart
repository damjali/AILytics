import 'package:flutter/material.dart';

class DataResultPage extends StatelessWidget {
  final Map<String, dynamic> processedData;
  final String fileName;

  const DataResultPage({
    super.key,
    required this.processedData,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> cleanedData =
        List<Map<String, dynamic>>.from(processedData["cleaned_data"]);

    List<String> columnNames = cleanedData.isNotEmpty
        ? cleanedData.first.keys.toList()
        : [];

    List<Map<String, dynamic>> displayedData =
        cleanedData.length > 20 ? cleanedData.sublist(0, 20) : cleanedData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Cleaning Results'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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
              'Cleaned Data Table (First 20 Rows)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double tableFontSize = constraints.maxWidth < 600
                      ? 12
                      : constraints.maxWidth < 1000
                          ? 14
                          : 16; // Adjust font size dynamically

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 16,
                            border: TableBorder.all(color: Colors.black54),
                            columns: columnNames.map((column) {
                              return DataColumn(
                                label: Text(
                                  column,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: tableFontSize,
                                  ),
                                ),
                              );
                            }).toList(),
                            rows: displayedData.map((rowData) {
                              return DataRow(
                                cells: columnNames.map((column) {
                                  return DataCell(
                                    Text(
                                      rowData[column]?.toString() ?? 'N/A',
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: tableFontSize),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Proceed to Dashboard Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Proceed to Dashboard',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
