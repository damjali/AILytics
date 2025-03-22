import 'package:flutter/material.dart';

class FinalResultPage extends StatelessWidget {
  final Map<String, dynamic> processedData;
  final Map<String, String> featureClassifications;
  final String fileName;

  const FinalResultPage({
    Key? key,
    required this.processedData,
    required this.featureClassifications,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve the calculated data from the backend response.
    double revenue = processedData['revenue']?.toDouble() ?? 0.0;
    double expenses = processedData['expenses']?.toDouble() ?? 0.0;
    double profit = processedData['profit']?.toDouble() ?? 0.0;
    double margin = processedData['margin']?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Final Results for $fileName"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Revenue: \$${revenue.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Expenses: \$${expenses.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Profit: \$${profit.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Margin: ${margin.toStringAsFixed(2)}%", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
