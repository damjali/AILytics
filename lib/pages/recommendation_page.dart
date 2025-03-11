// lib/pages/recommendation_page.dart

import 'package:flutter/material.dart';
import 'package:ailytics/navigation/app_navigation.dart';

class RecommendationPage extends StatelessWidget {
  final String? predictionType;
  final String? title;

  const RecommendationPage({
    Key? key,
    this.predictionType,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title != null ? '$title Recommendations' : 'Recommendations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Recommendations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-generated insights to improve your business',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: predictionType != null
                  ? _buildRecommendationsByType(context, predictionType!)
                  : _buildDefaultRecommendations(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsByType(BuildContext context, String type) {
    switch (type) {
      case 'sales':
        return ListView(
          children: [
            _buildRecommendationCard(
              context,
              'Q2 Growth Strategy',
              'Historical data shows Q2 as your strongest growth period. Focus marketing efforts during this period.',
              Icons.trending_up,
              Colors.green.shade100,
              [
                'Increase marketing budget allocation by 15% for Q2 campaigns',
                'Launch promotional offers in the month preceding Q2',
                'Focus on high-performing product categories from previous Q2 periods',
                'Prepare inventory levels 20% above baseline for anticipated demand'
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Product Focus',
              'Your product lines show varying performance. Prioritize resources effectively.',
              Icons.category,
              Colors.blue.shade100,
              [
                'Prioritize Product Line A for featured promotions',
                'Bundle slow-moving products with high-performers',
                'Consider phasing out bottom 10% of products by sales volume',
                'Develop cross-selling strategies for complementary products'
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Market Expansion',
              'Geographic analysis suggests growth opportunities in specific regions.',
              Icons.map,
              Colors.purple.shade100,
              [
                'Northeast region shows 32% higher conversion rates',
                'Consider expanding sales team in western territories',
                'Explore partnership opportunities with regional distributors',
                'Target marketing campaigns to high-potential geographic areas'
              ],
            ),
          ],
        );

      case 'revenue':
        return ListView(
          children: [
            _buildRecommendationCard(
              context,
              'Revenue Diversification',
              'Your business currently relies heavily on a single revenue stream. Consider multiple channels.',
              Icons.account_balance,
              Colors.amber.shade100,
              [
                'Develop subscription-based service options for core products',
                'Create premium tier offerings with 30-40% higher margins',
                'Explore licensing opportunities for proprietary technologies',
                'Consider strategic partnerships for co-branded products'
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Product Line B Optimization',
              'Product Line B shows promising growth indicators with 23% higher margins.',
              Icons.trending_up,
              Colors.green.shade100,
              [
                'Increase production capacity for high-margin items',
                'Develop 2-3 complementary products in this category',
                'Allocate additional marketing resources to this product line',
                'Consider price optimization based on price sensitivity analysis'
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Customer Segment Focus',
              'Analysis of customer segments reveals opportunities for increased revenue.',
              Icons.group,
              Colors.indigo.shade100,
              [
                'Enterprise clients generate 3.5x higher lifetime value',
                'Develop specialized onboarding for high-value segments',
                'Create retention programs for top 20% of customers by revenue',
                'Implement tiered pricing strategies aligned with segment value'
              ],
            ),
          ],
        );

      case 'expense':
        return ListView(
          children: [
            _buildRecommendationCard(
              context,
              'Manufacturing Cost Optimization',
              'Our analysis indicates potential for 12-15% annual savings through manufacturing optimizations.',
              Icons.factory,
              Colors.red.shade100,
              [
                'Implement just-in-time inventory management to reduce storage costs',
                'Negotiate volume-based discounts with top 5 suppliers',
                'Explore automation options for high-volume production lines',
                'Consider consolidating production facilities to reduce overhead'
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Operational Efficiency',
              'Administrative and operational expenses show optimization potential.',
              Icons.settings,
              Colors.orange.shade100,
              [
                'Review and consolidate software subscriptions (potential 8% savings)',
                'Implement energy efficiency measures in office facilities',
                'Consider hybrid work options to reduce facility costs',
                'Streamline approval processes for recurring expenses'
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationCard(
              context,
              'Strategic Cost Management',
              'Long-term cost structure improvements to consider implementing.',
              Icons.trending_down,
              Colors.teal.shade100,
              [
                'Develop a centralized procurement process for all departments',
                'Implement zero-based budgeting for non-essential departments',
                'Consider outsourcing non-core business functions',
                'Explore renewable energy options for long-term cost stability'
              ],
            ),
          ],
        );

      default:
        return _buildDefaultRecommendations(context);
    }
  }

  Widget _buildDefaultRecommendations(BuildContext context) {
    return ListView(
      children: [
        _buildEmptyRecommendationCard(
          context,
          'Cost Optimization',
          'Recommendations for reducing expenses',
          Icons.trending_down,
          Colors.red.shade100,
        ),
        const SizedBox(height: 16),
        _buildEmptyRecommendationCard(
          context,
          'Revenue Growth',
          'Strategies to increase sales and revenue',
          Icons.trending_up,
          Colors.green.shade100,
        ),
        const SizedBox(height: 16),
        _buildEmptyRecommendationCard(
          context,
          'Process Improvement',
          'Ideas to streamline operations',
          Icons.autorenew,
          Colors.blue.shade100,
        ),
        const SizedBox(height: 16),
        _buildEmptyRecommendationCard(
          context,
          'Customer Engagement',
          'Ways to improve customer satisfaction and loyalty',
          Icons.people,
          Colors.purple.shade100,
        ),
      ],
    );
  }

  Widget _buildEmptyRecommendationCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No data available for recommendations',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to upload page
                  navigationKey.currentState?.onItemTapped(1); // Index for upload page
                },
                child: const Text('Upload Data for AI Recommendations'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      List<String> actionItems,
      ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommended Actions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...actionItems.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(action),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}