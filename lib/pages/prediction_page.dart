import 'package:flutter/material.dart';
import 'package:ailytics/navigation/app_navigation.dart';
import 'package:ailytics/pages/revenue_recommendation_page.dart';
import 'package:ailytics/pages/sales_recommendation_page.dart';
import 'package:ailytics/pages/expense_recommendation_page.dart';

class PredictionPage extends StatelessWidget {
  const PredictionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI-Powered Predictions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Forecast future business performance',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildPredictionCard(
                context: context,
                title: 'Sales Forecast',
                shortRecommendation: 'Focus on Q2 sales strategies for highest growth potential.',
                predictionType: 'sales',
                apiEndpoint: "http://localhost:5000",
                recommendationPage: SalesRecommendationPage.new,
              ),
              const SizedBox(height: 16),
              _buildPredictionCard(
                context: context,
                title: 'Revenue Forecast',
                shortRecommendation: 'Diversify revenue streams with focus on product line B.',
                predictionType: 'revenue',
                apiEndpoint: "http://localhost:5000",
                recommendationPage: RevenueRecommendationPage.new,
              ),
              const SizedBox(height: 16),
              _buildPredictionCard(
                context: context,
                title: 'Expense Forecast',
                shortRecommendation: 'Optimize manufacturing costs for 12-15% annual savings.',
                predictionType: 'expense',
                apiEndpoint: "http://localhost:5000",
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
    required Widget Function({Key? key, required String predictionType, required String title, required String apiEndpoint}) recommendationPage,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No data available for prediction',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
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
            Text(
              shortRecommendation,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 140, // Adjusted button width
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to upload page
                      navigationKey.currentState?.onItemTapped(1);
                    },
                    child: const Text('Upload Data'),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to respective recommendation page with parameters
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => recommendationPage(
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