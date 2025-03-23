import 'package:flutter/material.dart';
import 'package:ailytics/navigation/app_navigation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:ailytics/providers/data_provider.dart';

import '../main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    // Get data from provider
    final dataProvider = Provider.of<DataProvider>(context);
    final processedData = dataProvider.processedData;
    final fileName = dataProvider.fileName;
    final hasData = dataProvider.hasData;

    print("Dashboard build: has data = $hasData");
    if (hasData) {
      print("File name: $fileName");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Refresh data if needed
              });
            },
          ),
        ],
      ),
      // Wrap the entire body in a SingleChildScrollView to make everything scrollable
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business Analytics Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasData
                    ? 'Analysis for: $fileName'
                    : 'Overview of your business performance',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildSummaryCards(hasData, processedData),
              const SizedBox(height: 24),
              const Text(
                'Performance Charts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Removed fixed height container that was causing overflow
              hasData ? _buildChartsScrollable(processedData) : _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool hasData, Map<String, dynamic>? processedData) {
    // If we have processed data, extract financial metrics
    double revenue = 0.0;
    double expenses = 0.0;
    double profit = 0.0;
    double margin = 0.0;

    if (hasData && processedData != null) {
      // We need to extract data from the cleaned_data directly since summary_stats is not provided
      final cleanedData = processedData['cleaned_data'] as List<dynamic>;

      if (cleanedData.isNotEmpty) {
        // Try to find financial columns in the data
        final firstRow = cleanedData.first as Map<String, dynamic>;

        // Look for revenue/income column
        for (var key in firstRow.keys) {
          String keyLower = key.toLowerCase();
          if (keyLower.contains('revenue') || keyLower.contains('income') || keyLower.contains('sales')) {
            revenue = _calculateAverage(cleanedData, key);
            break;
          }
        }

        // Look for expenses/cost column
        for (var key in firstRow.keys) {
          String keyLower = key.toLowerCase();
          if (keyLower.contains('expense') || keyLower.contains('cost')) {
            expenses = _calculateAverage(cleanedData, key);
            break;
          }
        }

        // If we couldn't find the columns, try to use the first two numeric columns as a fallback
        if (revenue == 0.0 && expenses == 0.0) {
          List<String> numericColumns = [];
          for (var key in firstRow.keys) {
            if (firstRow[key] is num) {
              numericColumns.add(key);
              if (numericColumns.length >= 2) break;
            }
          }

          if (numericColumns.length >= 1) {
            revenue = _calculateAverage(cleanedData, numericColumns[0]);
          }

          if (numericColumns.length >= 2) {
            expenses = _calculateAverage(cleanedData, numericColumns[1]);
          }
        }

        // Calculate profit and margin
        profit = revenue - expenses;
        margin = revenue > 0 ? (profit / revenue) * 100 : 0;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Revenue',
                '\$0.00', //can edit here for the predicted value later
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Expenses',
                '\$0.00', //can edit here for the predicted value later
                Icons.money_off,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Profit',
                '\$0.00', //can edit here for the predicted value later
                Icons.trending_up,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Margin',
                '0.00%', //can edit here for the predicted value later
                Icons.pie_chart,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateAverage(List<dynamic> data, String columnName) {
    double sum = 0;
    int count = 0;

    for (var item in data) {
      if (item is Map<String, dynamic>) {
        // Make sure we handle both numeric values and string representations of numbers
        if (item.containsKey(columnName)) {
          var value = item[columnName];
          if (value is num) {
            sum += value.toDouble();
            count++;
          } else if (value is String) {
            // Try to parse the string as a number
            try {
              sum += double.parse(value);
              count++;
            } catch (_) {
              // Not a number, ignore
            }
          }
        }
      }
    }

    return count > 0 ? sum / count : 0;
  }

  // Modified chart builder to work with scrolling
  Widget _buildChartsScrollable(Map<String, dynamic>? processedData) {
    print("Building charts with data structure: ${processedData?.keys}");
    if (processedData == null) {
      print("No processed data available");
      return _buildEmptyState();
    }

    final cleanedData = processedData['cleaned_data'] as List<dynamic>?;
    print("Cleaned data: ${cleanedData?.length} rows");

    if (cleanedData == null || cleanedData.isEmpty) {
      return _buildEmptyState();
    }

    // Determine if we have time-series data
    bool hasTimeSeriesData = false;
    String? timeColumn;

    // Check first row for date/time columns
    if (cleanedData.isNotEmpty) {
      final firstRow = cleanedData.first as Map<String, dynamic>;
      for (var key in firstRow.keys) {
        String keyLower = key.toLowerCase();
        if (keyLower.contains('date') ||
            keyLower.contains('month') ||
            keyLower.contains('year') ||
            keyLower.contains('time')) {
          hasTimeSeriesData = true;
          timeColumn = key;
          break;
        }
      }
    }

    // Create summary stats if they don't exist
    Map<String, dynamic> summaryStats = {};

    if (cleanedData.isNotEmpty) {
      final firstRow = cleanedData.first as Map<String, dynamic>;

      // Calculate stats for numeric columns
      for (var key in firstRow.keys) {
        if (firstRow[key] is num || _isNumericString(firstRow[key])) {
          // Calculate min, max, mean, median for this column
          List<double> values = [];

          for (var row in cleanedData) {
            var item = row as Map<String, dynamic>;
            if (item.containsKey(key)) {
              var value = item[key];
              if (value is num) {
                values.add(value.toDouble());
              } else if (value is String) {
                try {
                  values.add(double.parse(value));
                } catch (_) {
                  // Skip non-numeric strings
                }
              }
            }
          }

          if (values.isNotEmpty) {
            values.sort();
            double sum = values.reduce((a, b) => a + b);
            double mean = sum / values.length;
            double median = values.length % 2 == 0
                ? (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2
                : values[values.length ~/ 2];

            summaryStats[key] = {
              'min': values.first,
              'max': values.last,
              'mean': mean,
              'median': median,
            };
          }
        }
      }
    }

    // Use Column instead of ListView to allow the outer scroll to work properly
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar Chart for Numerical Data
        if (summaryStats.isNotEmpty) ...[
          _buildBarChart(summaryStats),
          const SizedBox(height: 24),
        ],

        // Line Chart if we have time series data
        if (hasTimeSeriesData && timeColumn != null) ...[
          _buildLineChart(cleanedData, timeColumn),
          const SizedBox(height: 24),
        ],

        // Pie Chart for Category Distribution
        _buildPieChart(cleanedData),
      ],
    );
  }

  bool _isNumericString(dynamic value) {
    if (value is! String) return false;
    try {
      double.parse(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildBarChart(Map<String, dynamic> summaryStats) {
    // Get the numerical columns from summary stats
    final numericalColumns = summaryStats.keys.toList();

    if (numericalColumns.isEmpty) {
      return const SizedBox();
    }

    // Limit to 5 columns for better visibility
    final limitedColumns = numericalColumns.length > 5
        ? numericalColumns.sublist(0, 5)
        : numericalColumns;

    // Find the maximum value for scaling (use the actual max values, but keep the bars proportional)
    double maxValue = limitedColumns
        .map((col) => (summaryStats[col]['max'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    // Calculate baseline Y-axis min (set to 0 for better data representation)
    double minY = 0;

    // Adjust maxY to give some headroom (20% above the max value)
    double maxY = maxValue * 1.2;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Numerical Data Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Statistical overview of numerical columns',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280, // Increased height to accommodate axis labels
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 5, right:45),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: minY,
                    maxY: maxY,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Value',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Metric',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= limitedColumns.length) {
                              return const Text('');
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                limitedColumns[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      limitedColumns.length,
                          (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (summaryStats[limitedColumns[index]]['mean'] as num).toDouble(),
                            color: Colors.blue,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: (summaryStats[limitedColumns[index]]['median'] as num).toDouble(),
                            color: Colors.green,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.shade700,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String measure = rodIndex == 0 ? 'Mean' : 'Median';
                          double value = rod.toY;
                          return BarTooltipItem(
                            '$measure: ${value.toStringAsFixed(2)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, 'Mean'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.green, 'Median'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> data, String timeColumn) {
    // Find a numerical column to plot
    String? valueColumn;
    if (data.isNotEmpty) {
      final firstRow = data.first as Map<String, dynamic>;
      for (var key in firstRow.keys) {
        if (key != timeColumn && (firstRow[key] is num || _isNumericString(firstRow[key]))) {
          valueColumn = key;
          break;
        }
      }
    }

    if (valueColumn == null) {
      return const SizedBox();
    }

    // Sort data by time column if possible
    try {
      data.sort((a, b) {
        final aMap = a as Map<String, dynamic>;
        final bMap = b as Map<String, dynamic>;
        return aMap[timeColumn].toString().compareTo(bMap[timeColumn].toString());
      });
    } catch (e) {
      // If sorting fails, just use the data as is
    }

    // Limit to 10 data points to prevent overcrowding
    final limitedData = data.length > 10 ? data.sublist(0, 10) : data;

    // Prepare line chart data points
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (var i = 0; i < limitedData.length; i++) {
      final item = limitedData[i] as Map<String, dynamic>;
      if (item.containsKey(valueColumn)) {
        var value = item[valueColumn];
        double numValue = 0.0;

        if (value is num) {
          numValue = value.toDouble();
        } else if (value is String) {
          try {
            numValue = double.parse(value);
          } catch (_) {
            continue; // Skip if can't parse
          }
        } else {
          continue; // Skip if not a number or string
        }

        spots.add(FlSpot(i.toDouble(), numValue));
        labels.add(item[timeColumn].toString());
      }
    }

    if (spots.isEmpty) {
      return const SizedBox();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis: $valueColumn',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time-based performance tracking',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280, // Increased height to accommodate axis labels
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 5, right:45),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      verticalInterval: 1,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          valueColumn,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text(
                          timeColumn,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: false, // Hide x-axis labels for date values
                          getTitlesWidget: (value, meta) {
                            return const Text('');
                          },
                          reservedSize: 10, // Keep minimal space for the axis line
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.shade700,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            int index = spot.x.toInt();
                            if (index >= 0 && index < labels.length) {
                              return LineTooltipItem(
                                '${labels[index]}: ${spot.y.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<dynamic> data) {
    // Find a categorical column to chart
    String? categoryColumn;
    if (data.isNotEmpty) {
      final firstRow = data.first as Map<String, dynamic>;
      for (var key in firstRow.keys) {
        if (firstRow[key] is String && !_isNumericString(firstRow[key])) {
          if (!key.toLowerCase().contains('date') &&
              !key.toLowerCase().contains('time') &&
              !key.toLowerCase().contains('id')) {
            categoryColumn = key;
            break;
          }
        }
      }
    }

    // If no categorical column was found, try to find any column that can be categorized
    if (categoryColumn == null && data.isNotEmpty) {
      final firstRow = data.first as Map<String, dynamic>;
      for (var key in firstRow.keys) {
        // Skip date/time/id columns
        if (!key.toLowerCase().contains('date') &&
            !key.toLowerCase().contains('time') &&
            !key.toLowerCase().contains('id')) {
          categoryColumn = key;
          break;
        }
      }
    }

    if (categoryColumn == null) {
      return const SizedBox();
    }

    // Count occurrences of each category
    final Map<String, int> categoryCounts = {};
    for (var item in data) {
      final row = item as Map<String, dynamic>;
      if (row.containsKey(categoryColumn)) {
        final category = row[categoryColumn].toString();
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    // Limit to top 5 categories for better visualization
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final limitedCategories = sortedCategories.take(5).toList();

    if (limitedCategories.isEmpty) {
      return const SizedBox();
    }

    // Colors for the pie chart sections
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution: $categoryColumn',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Distribution of top ${limitedCategories.length} categories',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: List.generate(
                    limitedCategories.length,
                        (index) {
                      final double percentage = limitedCategories[index].value * 100 /
                          categoryCounts.values.reduce((a, b) => a + b);
                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: limitedCategories[index].value.toDouble(),
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                limitedCategories.length,
                    (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: colors[index % colors.length],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          limitedCategories[index].key,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${limitedCategories[index].value})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload data to see visualizations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Switch to the Upload tab (index 1) using the navigation key
              navigationKey.currentState?.onItemTapped(1);
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Data'),
          ),
        ],
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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