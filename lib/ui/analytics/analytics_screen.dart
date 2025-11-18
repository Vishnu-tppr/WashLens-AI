import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

/// Analytics/Statistics Screen
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.015;
    final cardSpacing = screenHeight * 0.012;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: TextStyle(fontSize: screenWidth * 0.05),
        ),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.menu, size: screenWidth * 0.06),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top 3 Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Items\nGiven',
                    '42',
                    'This Month',
                    AppTheme.surface,
                    AppTheme.textPrimary,
                    screenWidth,
                    screenHeight,
                  ),
                ),
                SizedBox(width: cardSpacing),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Most Missing',
                    'Socks',
                    null,
                    AppTheme.surface,
                    AppTheme.textPrimary,
                    screenWidth,
                    screenHeight,
                  ),
                ),
                SizedBox(width: cardSpacing),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Dhobi Risk',
                    'High',
                    null,
                    const Color(0xFFEBF4FF),
                    AppTheme.error,
                    screenWidth,
                    screenHeight,
                  ),
                ),
              ],
            ),

            SizedBox(height: cardSpacing * 1.2),

            // Category History Chart
            Container(
              padding: EdgeInsets.all(screenWidth * 0.035),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.004),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '42 items',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: screenWidth * 0.065,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.005),
                        child: Text(
                          '+5% this month',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  SizedBox(
                    height: screenHeight * 0.18,
                    child: _buildBarChart(screenWidth),
                  ),
                ],
              ),
            ),

            SizedBox(height: cardSpacing * 1.2),

            // Return Delay Pattern
            Expanded(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.035),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Return Delay Pattern',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDelayBar('Mon', 0.4, screenWidth, screenHeight),
                          _buildDelayBar('Tue', 0.2, screenWidth, screenHeight),
                          _buildDelayBar('Wed', 0.7, screenWidth, screenHeight),
                          _buildDelayBar('Thu', 0.9, screenWidth, screenHeight),
                          _buildDelayBar('Fri', 0.5, screenWidth, screenHeight),
                          _buildDelayBar('Sat', 0.3, screenWidth, screenHeight),
                          _buildDelayBar('Sun', 0.1, screenWidth, screenHeight),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String? subtitle,
    Color bgColor,
    Color valueColor,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: screenWidth * 0.028,
              height: 1.3,
            ),
          ),
          SizedBox(height: screenHeight * 0.006),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: screenWidth * 0.065,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: screenHeight * 0.002),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: screenWidth * 0.026,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarChart(double screenWidth) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 15,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final style = TextStyle(
                  fontSize: screenWidth * 0.028,
                  color: AppTheme.textSecondary,
                );
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = 'Shirts';
                    break;
                  case 1:
                    text = 'Tees';
                    break;
                  case 2:
                    text = 'Pants';
                    break;
                  case 3:
                    text = 'Socks';
                    break;
                  case 4:
                    text = 'Misc';
                    break;
                  default:
                    text = '';
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 7, AppTheme.categoryShirt.withOpacity(0.6)),
          _makeGroupData(1, 10, AppTheme.categoryTShirt.withOpacity(0.6)),
          _makeGroupData(2, 5, AppTheme.categoryPants.withOpacity(0.6)),
          _makeGroupData(3, 14, AppTheme.primary),
          _makeGroupData(4, 8, AppTheme.categoryShorts.withOpacity(0.6)),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildDelayBar(String day, double value, double screenWidth, double screenHeight) {
    return Row(
      children: [
        SizedBox(
          width: screenWidth * 0.08,
          child: Text(
            day,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: screenHeight * 0.025,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(screenWidth * 0.015),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(screenWidth * 0.015),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
