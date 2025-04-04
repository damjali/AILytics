import 'package:flutter/material.dart';
import 'package:ailytics/navigation/app_navigation.dart';
import 'package:provider/provider.dart';
import 'package:ailytics/providers/data_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExpenseRecommendationPage extends StatefulWidget {
  final String predictionType;
  final String title;
  final String apiEndpoint;

  const ExpenseRecommendationPage({
    super.key,
    required this.predictionType,
    required this.title,
    required this.apiEndpoint,
  });

  @override
  State<ExpenseRecommendationPage> createState() => _ExpenseRecommendationPageState();
}

class _ExpenseRecommendationPageState extends State<ExpenseRecommendationPage> {
  bool _isLoading = false;
  List<dynamic> _recommendations = [];
  String _errorMessage = '';
  String _dataInsights = '';
  Map<String, dynamic> _correlationInsights = {};

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    if (!dataProvider.hasData) {
        setState(() {
            _errorMessage = 'No data available for recommendations';
        });
        return;
    }

    setState(() {
        _isLoading = true;
        _errorMessage = '';  // Clear previous errors
    });

    try {
        final String predictionType = widget.predictionType;
        
        // Enhanced data context to match backend expectations
        final Map<String, dynamic> dataContext = {
            'dataType': dataProvider.dataType ?? 'Not specified',
            'timeRange': dataProvider.timeRange.isNotEmpty ? dataProvider.timeRange : 'Not specified',
            'dataDescription': dataProvider.dataDescription.isNotEmpty ? dataProvider.dataDescription : 'Not specified',
        };

        // Format payload to match what the backend expects
        final payload = {
            'predictionType': predictionType,
            'dataContext': dataContext,
            'data': {
                'cleaned_data': dataProvider.processedData!['cleaned_data'] ?? [],
                'original_file': dataProvider.fileName ?? 'unknown'
            }
        };

        final response = await http.post(
            Uri.parse(widget.apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
        );

        if (response.statusCode == 200) {
            final data = json.decode(response.body);
            setState(() {
                _recommendations = data['recommendations'] ?? [];
                _dataInsights = data['insights'] ?? '';
                _isLoading = false;
            });
        } else {
            setState(() {
                _errorMessage = 'Failed to load recommendations: ${response.statusCode}';
                _isLoading = false;
            });
        }
    } catch (e) {
        setState(() {
            _errorMessage = 'Error: ${e.toString()}';
            _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictionType = widget.predictionType;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecommendations,
            tooltip: 'Refresh recommendations',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart ${predictionType.capitalize()} Recommendations',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Powered Analysis',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Data insights section
                  if (_dataInsights.isNotEmpty)
                    _buildDataInsightsCard(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _errorMessage.isNotEmpty && _recommendations.isEmpty
                        ? _buildErrorState()
                        : _recommendations.isEmpty
                            ? _buildEmptyState()
                            : _buildRecommendationsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analyzing your data to generate specific recommendations...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataInsightsCard() {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Key Data Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _dataInsights,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return ListView.builder(
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildRecommendationCard(
            context,
            recommendation['title'] ?? 'Recommendation',
            recommendation['description'] ?? 'No description available',
            _getIconForRecommendation(recommendation['title'] ?? ''),
            _getColorForRecommendation(index),
            List<String>.from(recommendation['action_items'] ?? []),
            recommendation['data_evidence'] ?? 'Based on data analysis',
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchRecommendations,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recommendations available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try uploading different data or changing prediction settings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchRecommendations,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForRecommendation(String title) {
    final String lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('cost') || lowerTitle.contains('expense')) {
      return Icons.trending_down;
    } else if (lowerTitle.contains('revenue') || lowerTitle.contains('growth') || lowerTitle.contains('sales')) {
      return Icons.trending_up;
    } else if (lowerTitle.contains('customer') || lowerTitle.contains('client')) {
      return Icons.people;
    } else if (lowerTitle.contains('product')) {
      return Icons.category;
    } else if (lowerTitle.contains('market') || lowerTitle.contains('region')) {
      return Icons.map;
    } else if (lowerTitle.contains('process') || lowerTitle.contains('operations')) {
      return Icons.settings;
    } else if (lowerTitle.contains('optimize')) {
      return Icons.speed;
    } else if (lowerTitle.contains('strategy') || lowerTitle.contains('framework')) {
      return Icons.auto_graph;
    } else if (lowerTitle.contains('performance') || lowerTitle.contains('enhancement')) {
      return Icons.trending_up;
    } else {
      return Icons.lightbulb_outline;
    }
  }

  Color _getColorForRecommendation(int index) {
    List<Color> colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.amber.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.orange.shade100,
    ];
    
    return colors[index % colors.length];
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> actionItems,
    String dataEvidence,
  ) {
    return Card(
      elevation: 3,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
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
                fontSize: 15,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            // Data Evidence Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.data_usage, size: 14, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        'DATA EVIDENCE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dataEvidence,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(fontSize: 14),
                    ),
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

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}