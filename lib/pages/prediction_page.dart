import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';
import 'package:ailytics/navigation/app_navigation.dart';
import 'package:ailytics/pages/revenue_recommendation_page.dart';
import 'package:ailytics/pages/sales_recommendation_page.dart';
import 'package:ailytics/pages/expense_recommendation_page.dart';
import 'package:csv/csv.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  Map<String, List<Map<String, dynamic>>> forecastDataByType = {
    'sales': [],
    'revenue': [],
    'expense': [],
  };
  String selectedPeriod = '1_month';

  @override
  void initState() {
    super.initState();
    fetchAllForecastData();
  }

  Future<void> fetchAllForecastData() async {
    await fetchForecastData('sales');
    await fetchForecastData('revenue');
    await fetchForecastData('expense');
  }

  Future<void> fetchForecastData(String type) async {
    try {
      final rawData = await rootBundle.loadString('assets/forecast_april_2025.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        rawData,
        eol: '\n',
      );

      final headers = csvTable.first;
      final int dateIndex = headers.indexOf('date');
      final int predictedSalesIndex = headers.indexOf('predicted_sales');
      final int predictedRevenueIndex = headers.indexOf('predicted_revenue');
      final int predictedExpenseIndex = headers.indexOf('predicted_expense');

      final List<Map<String, dynamic>> filteredData = csvTable.skip(1).map((row) {
        return {
          'Date': row[dateIndex],
          'Predicted_Sales': (row[predictedSalesIndex] ?? 0).toDouble(),
          'Predicted_Revenue': (row[predictedRevenueIndex] ?? 0).toDouble(),
          'Predicted_Expenses': (row[predictedExpenseIndex] ?? 0).toDouble(),
        };
      }).toList();

      setState(() {
        forecastDataByType[type] = filteredData;
      });
    } catch (e) {
      debugPrint('Error loading CSV for $type: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Predictions')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI-Powered Predictions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Forecast future business performance',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children:
                    ['1_month', '3_months', '5_months', '1_year'].map((period) {
                  return ChoiceChip(
                    label: Text(period.replaceAll('_', ' ')),
                    selected: selectedPeriod == period,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedPeriod = period;
                          fetchAllForecastData();
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _buildPredictionCard(
                context: context,
                title: 'Sales Forecast',
                shortRecommendation:
                    'Focus on Q2 sales strategies for highest growth potential.',
                predictionType: 'sales',
                apiEndpoint: 'http://localhost:5000/get-sales-recommendations',
                recommendationPage: SalesRecommendationPage.new,
              ),
              const SizedBox(height: 16),
              _buildPredictionCard(
                context: context,
                title: 'Revenue Forecast',
                shortRecommendation:
                    'Diversify revenue streams with focus on product line B.',
                predictionType: 'revenue',
                apiEndpoint:
                    'http://localhost:5000/get-revenue-recommendations',
                recommendationPage: RevenueRecommendationPage.new,
              ),
              const SizedBox(height: 16),
              _buildPredictionCard(
                context: context,
                title: 'Expense Forecast',
                shortRecommendation:
                    'Optimize manufacturing costs for 12-15% annual savings.',
                predictionType: 'expense',
                apiEndpoint:
                    'http://localhost:5000/get-expense-recommendations',
                recommendationPage: ExpenseRecommendationPage.new,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionCard({
    required BuildContext context,
    required String title,
    required String shortRecommendation,
    required String predictionType,
    required String apiEndpoint,
    required Widget Function({
      Key? key,
      required String predictionType,
      required String title,
      required String apiEndpoint,
    })
    recommendationPage,
  }) {
    final forecastData = forecastDataByType[predictionType] ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            forecastData.isEmpty
                ? const Text('Loading forecast data...')
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: (forecastData.length / 5).floorToDouble(),
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= forecastData.length)
                                  return const SizedBox();
                                return Text(
                                  forecastData[index]['Date'].substring(5),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 500,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              forecastData.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                forecastData[i]['Predicted_Revenue'].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: Colors.blue,
                            dotData: FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: List.generate(
                              forecastData.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                forecastData[i]['Predicted_Expenses'].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: Colors.red,
                            dotData: FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: List.generate(
                              forecastData.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                forecastData[i]['Predicted_Sales'].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: Colors.green,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Recommendation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(shortRecommendation, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      navigationKey.currentState?.onItemTapped(1);
                    },
                    child: const Text('Upload Data'),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => recommendationPage(
                              predictionType: predictionType,
                              title: title,
                              apiEndpoint: apiEndpoint,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
