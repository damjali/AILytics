import 'package:flutter/material.dart';

class ProcessedDataPage extends StatelessWidget {
  final Map<String, dynamic> processedData;
  const ProcessedDataPage({Key? key, required this.processedData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final revenue = processedData['revenue'] ?? 0;
    final expenses = processedData['expenses'] ?? 0;
    final profit = processedData['profit'] ?? 0;
    final margin = processedData['margin'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Processed Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Revenue: \$${revenue.toString()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Expenses: \$${expenses.toString()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Profit: \$${profit.toString()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Margin: ${margin.toString()}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
