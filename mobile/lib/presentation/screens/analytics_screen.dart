import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/analytics_model.dart';
import '../providers/analytics_provider.dart';
import '../../core/constants/category_icons.dart';

/// Purpose: Financial Intelligence & Analytics Hub Screen
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Financial Intelligence Hub)

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  final List<Color> _chartColors = const [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Rose
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    ref.read(analyticsProvider.notifier).fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final insights = state.insights;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Financial Intelligence Hub',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FINANCIAL HEALTH & KEY INSIGHTS ---
                      if (insights != null) ...[
                        Text(
                          'Financial Health & Metrics',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            _buildHealthCard(
                              title: 'Savings Rate',
                              value: '${insights.savingsRate.toStringAsFixed(1)}%',
                              subtitle: insights.savingsRate >= 30
                                  ? 'High Savings'
                                  : (insights.savingsRate >= 15 ? 'Healthy' : 'Low Savings'),
                              icon: Icons.savings_rounded,
                              accentColor: AppColors.incomeEmerald,
                            ),
                            _buildHealthCard(
                              title: 'Emergency Runway',
                              value: '${insights.emergencyFundMonths} Months',
                              subtitle: '${insights.burnRate} Days Burn Rate',
                              icon: Icons.shield_rounded,
                              accentColor: AppColors.primary,
                            ),
                            _buildHealthCard(
                              title: 'Avg Daily Spend',
                              value: currencyFormatter.format(insights.avgDailyExpense),
                              subtitle: 'Per Day this Month',
                              icon: Icons.local_fire_department_rounded,
                              accentColor: AppColors.transferAmber,
                            ),
                            _buildHealthCard(
                              title: 'Credit Exposure',
                              value: '${insights.creditExposureRatio.toStringAsFixed(1)}%',
                              subtitle: insights.creditExposureRatio > 30 ? 'High Liability' : 'Low Risk',
                              icon: Icons.speed_rounded,
                              accentColor: insights.creditExposureRatio > 30 ? AppColors.expenseRose : AppColors.creditCyan,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // --- MONTHLY INCOME VS EXPENSE TREND ---
                      Text(
                        'Income vs Expense Trend',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 10),
                      _buildMonthlyTrendChart(state.monthlyTrends),
                      const SizedBox(height: 24),

                      // --- CATEGORY EXPENSE BREAKDOWN ---
                      Text(
                        'Category Expense Breakdown',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryBreakdownCard(state.categories),
                      const SizedBox(height: 24),

                      // --- RECURRING SUBSCRIPTIONS ---
                      Text(
                        'Recurring Subscriptions & Bills',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 10),
                      _buildSubscriptionsCard(state.subscriptions),
                      const SizedBox(height: 24),

                      // --- ITEM INFLATION TRACKER ---
                      Text(
                        'Item Price Inflation Tracker',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 10),
                      _buildInflationCard(state.inflationItems),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHealthCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<MonthlyTrendModel> trends) {
    if (trends.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          'No monthly trend data available yet.',
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Group trends by month/year
    final Map<String, Map<String, double>> grouped = {};
    for (final t in trends) {
      final key = '${t.month}/${t.year}';
      grouped.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
      grouped[key]![t.type] = t.total;
    }

    final keys = grouped.keys.toList();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    double maxVal = 1000.0;
    for (final v in grouped.values) {
      if ((v['income'] ?? 0) > maxVal) maxVal = v['income']!;
      if ((v['expense'] ?? 0) > maxVal) maxVal = v['expense']!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.incomeEmerald, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Income', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.expenseRose, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Expense', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${isIncome ? "Income" : "Expense"}\n₹${rod.toY.round()}',
                        GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < keys.length) {
                          final parts = keys[idx].split('/');
                          final mIdx = (int.tryParse(parts[0]) ?? 1) - 1;
                          final mName = (mIdx >= 0 && mIdx < 12) ? monthNames[mIdx] : parts[0];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              mName,
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: keys.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final data = grouped[entry.value]!;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: data['income'] ?? 0,
                        color: AppColors.incomeEmerald,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: data['expense'] ?? 0,
                        color: AppColors.expenseRose,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(List<CategoryBreakdownModel> categories) {
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          'No expense category breakdown available.',
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: categories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  return PieChartSectionData(
                    color: CategoryIcons.parseColor(cat.color, defaultColor: _chartColors[idx % _chartColors.length]),
                    value: cat.total,
                    title: '',
                    radius: 35,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final Color catColor = CategoryIcons.parseColor(cat.color, defaultColor: _chartColors[index % _chartColors.length]);
              final IconData iconData = CategoryIcons.getIcon(cat.icon);

              if (cat.subcategories.isEmpty) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: catColor, size: 18),
                  ),
                  title: Text(cat.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  trailing: Text(
                    currencyFormatter.format(cat.total),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                );
              }

              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 48, bottom: 8),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: catColor, size: 18),
                  ),
                  title: Text(cat.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormatter.format(cat.total),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                  children: cat.subcategories.map((sub) {
                    final subIcon = CategoryIcons.getIcon(sub.icon);
                    final subColor = CategoryIcons.parseColor(sub.color, defaultColor: catColor);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(subIcon, size: 14, color: subColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('↳ ${sub.name}', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant)),
                          ),
                          Text(
                            currencyFormatter.format(sub.total),
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsCard(List<SubscriptionModel> subscriptions) {
    if (subscriptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          'No active recurring subscriptions detected.',
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: subscriptions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
        itemBuilder: (context, index) {
          final sub = subscriptions[index];
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.subscriptions_outlined, color: AppColors.primary, size: 18),
            ),
            title: Text(sub.merchantName, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            subtitle: Text(sub.frequency, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant)),
            trailing: Text(
              currencyFormatter.format(sub.amount),
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.expenseRose),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInflationCard(List<ItemInflationModel> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          'No price changes detected yet. Record itemized transactions over time to track price changes!',
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
        itemBuilder: (context, index) {
          final item = items[index];
          final isIncrease = item.priceChange > 0;
          return ListTile(
            title: Text(item.itemName, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            subtitle: Text(
              'First: ₹${item.firstUnitPrice} ➔ Latest: ₹${item.lastUnitPrice}',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isIncrease ? AppColors.expenseRose : AppColors.incomeEmerald).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isIncrease ? "+" : ""}${item.percentageChange.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isIncrease ? AppColors.expenseRose : AppColors.incomeEmerald,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
