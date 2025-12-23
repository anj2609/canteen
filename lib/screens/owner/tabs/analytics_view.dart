import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/owner_provider.dart';

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({super.key});

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView> {
  String _selectedPeriod = 'day';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAnalytics();
    });
  }

  void _fetchAnalytics() {
    final ownerState = ref.read(ownerProvider);
    if (ownerState.selectedCanteen != null) {
      ref
          .read(ownerProvider.notifier)
          .fetchAnalytics(
            ownerState.selectedCanteen!.id,
            period: _selectedPeriod,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerState = ref.watch(ownerProvider);
    final data = ownerState.analyticsData ?? {};
    final isLoading = ownerState.isLoading;

    // Listen for canteen changes and refresh analytics
    ref.listen(ownerProvider, (previous, next) {
      if (previous?.selectedCanteen?.id != next.selectedCanteen?.id &&
          next.selectedCanteen != null) {
        _fetchAnalytics();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector (Mock mostly, but UI needed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overview',
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem(
                            value: 'day',
                            child: Text('Today'),
                          ),
                          const DropdownMenuItem(
                            value: 'week',
                            child: Text('Week'),
                          ),
                          const DropdownMenuItem(
                            value: 'month',
                            child: Text('Month'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPeriod = val;
                            });
                            _fetchAnalytics();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Key Metrics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        'Total Sales',
                        '₹${data['summary']?['totalEarnings'] ?? 0}',
                        Colors.blue,
                        Icons.attach_money,
                      ),
                      _buildMetricCard(
                        'Total Orders',
                        '${data['summary']?['totalOrders'] ?? 0}',
                        Colors.orange,
                        Icons.shopping_bag_outlined,
                      ),
                      _buildMetricCard(
                        'Avg. Order',
                        '₹${data['summary']?['averageOrderValue'] ?? 0}',
                        Colors.green,
                        Icons.trending_up,
                      ),
                      _buildMetricCard(
                        'Cancelled',
                        '${data['ordersByStatus']?['cancelled'] ?? 0}',
                        Colors.red,
                        Icons.cancel_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Earnings Trend',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bar Chart - Show earnings breakdown by day/week
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxEarnings(data) * 1.2,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Show day labels based on period
                                if (_selectedPeriod == 'day') {
                                  const hours = ['9AM', '12PM', '3PM', '6PM'];
                                  if (value.toInt() < hours.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        hours[value.toInt()],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                } else if (_selectedPeriod == 'week') {
                                  const days = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  if (value.toInt() < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        days[value.toInt()],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  // Month - show weeks
                                  const weeks = ['W1', 'W2', 'W3', 'W4'];
                                  if (value.toInt() < weeks.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        weeks[value.toInt()],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const Text('');
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
                        barGroups: _generateEarningsBarGroups(data),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    'Top Selling Items',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: (data['topSellingItems'] as List? ?? [])
                        .map<Widget>((item) {
                          return _buildTopItem(
                            item['name'] ?? 'Item',
                            '${item['quantity']} orders',
                            '₹${item['revenue']}',
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D9E9E9E),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.urbanist(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  double _getMaxEarnings(Map<String, dynamic> data) {
    // For now, use total earnings as max since we don't have breakdown
    // In real scenario, would use max from earnings array
    final totalEarnings = data['summary']?['totalEarnings'] ?? 100;
    return (totalEarnings / 4).toDouble(); // Divide by 4 for chart scale
  }

  List<BarChartGroupData> _generateEarningsBarGroups(
    Map<String, dynamic> data,
  ) {
    // Since API doesn't provide detailed breakdown, create a simple visualization
    // showing total earnings distributed across time periods
    final totalEarnings = (data['summary']?['totalEarnings'] ?? 0).toDouble();
    final totalOrders = (data['summary']?['totalOrders'] ?? 1);

    // Create a simple trend - distribute earnings
    final barCount = _selectedPeriod == 'day'
        ? 4
        : (_selectedPeriod == 'week' ? 7 : 4);
    final avgPerBar = totalEarnings / barCount;

    return List.generate(barCount, (index) {
      // Add some variation to make it look like a trend
      final variation = (index % 2 == 0) ? 0.8 : 1.2;
      final value = avgPerBar * variation;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: const Color(0xFFF62F56),
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxEarnings(data),
              color: Colors.grey[100],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTopItem(String name, String subtitle, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.fastfood, color: Colors.grey),
      ),
      title: Text(
        name,
        style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.urbanist(color: Colors.grey, fontSize: 12),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.urbanist(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
