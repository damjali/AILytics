import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditableFinancialStats extends StatefulWidget {
  final double initialRevenue;
  final double initialExpenses;

  const EditableFinancialStats({
    Key? key,
    required this.initialRevenue,
    required this.initialExpenses,
  }) : super(key: key);

  @override
  _EditableFinancialStatsState createState() => _EditableFinancialStatsState();
}

class _EditableFinancialStatsState extends State<EditableFinancialStats> {
  late TextEditingController revenueController;
  late TextEditingController expensesController;
  late double revenue;
  late double expenses;

  @override
  void initState() {
    super.initState();
    revenue = widget.initialRevenue;
    expenses = widget.initialExpenses;
    revenueController = TextEditingController(text: revenue.toString());
    expensesController = TextEditingController(text: expenses.toString());
  }

  @override
  void dispose() {
    revenueController.dispose();
    expensesController.dispose();
    super.dispose();
  }

  // Recalculate profit and margin based on revenue and expenses.
  double get profit => revenue - expenses;
  double get margin => revenue > 0 ? (profit / revenue) * 100 : 0;

  // Update state when either revenue or expenses change.
  void updateStats() {
    setState(() {
      revenue = double.tryParse(revenueController.text) ?? 0.0;
      expenses = double.tryParse(expensesController.text) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    String revenueFormatted =
        NumberFormat("#,##0.00", "en_US").format(revenue);
    String expensesFormatted =
        NumberFormat("#,##0.00", "en_US").format(expenses);
    String profitFormatted =
        NumberFormat("#,##0.00", "en_US").format(profit);
    String marginFormatted =
        NumberFormat("#,##0.00", "en_US").format(margin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editable revenue field
        TextFormField(
          controller: revenueController,
          decoration: const InputDecoration(
            labelText: "Revenue",
            prefixText: "\$",
            border: OutlineInputBorder(),
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => updateStats(),
        ),
        const SizedBox(height: 16),
        // Editable expenses field
        TextFormField(
          controller: expensesController,
          decoration: const InputDecoration(
            labelText: "Expenses",
            prefixText: "\$",
            border: OutlineInputBorder(),
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => updateStats(),
        ),
        const SizedBox(height: 24),
        // Display computed profit and margin in summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Profit',
                '\$$profitFormatted',
                Icons.trending_up,
                profit < 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Margin',
                '$marginFormatted%',
                Icons.pie_chart,
                margin < 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
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
