import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:softspend/controllers/expense_controller.dart';
import 'package:softspend/controllers/settings_controller.dart';
import 'package:softspend/utils/app_colors.dart';
import 'package:softspend/utils/ui_helpers.dart';

class AnalyticsView extends StatelessWidget {
  final ExpenseController controller = Get.find();

  // Actually we can access it via Get.find since it was put in DashboardPage
  // But cleaner to explicitly find it or add it to ExpenseController if we want to chain access like above.
  // Ideally, ExpenseController shouldn't depend on SettingsController if not needed logic-wise.
  // But for the tooltip above I used `controller.settingsController`. I should fix that.

  // Let's explicitly find it here.
  final SettingsController settingsController = Get.find();

  AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          _buildMonthSelector(context),
          const SizedBox(height: 16),
          _buildMonthlyTotal(context),

          const SizedBox(height: 24),
          _buildBudgetCard(context),
          const SizedBox(height: 24),
          _buildPieChartSection(context),
          const SizedBox(height: 32),
          _buildBarChartSection(context),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              lightHaptic();
              controller.changeMonth(-1);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: theme.iconTheme.color,
            ),
          ),
          Obx(
            () => Text(
              DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              lightHaptic();
              controller.changeMonth(1);
            },
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.iconTheme.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTotal(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Total Spent',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => CountUpText(
            value: controller.analyticsTotal,
            prefix: settingsController.currencySymbol.value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Obx(() {
              final data = controller.analyticsCategoryBreakdown;
              if (data.isEmpty) {
                return const Center(
                  child: EmptyStateWidget(
                    message: "No data for current period",
                    icon: Icons.pie_chart_outline,
                  ),
                );
              }
              return PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: data.entries.map((e) {
                    final color = _getColorForCategory(e.key);
                    return PieChartSectionData(
                      color: color,
                      value: e.value,
                      title: e.value.toStringAsFixed(0),
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: ['Food', 'Travel', 'Shopping', 'Bills'].map((category) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getColorForCategory(category),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBarChartSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Obx(() {
              final data = controller.analyticsTimeBreakdown;
              if (data.values.every((v) => v == 0)) {
                return const Center(
                  child: EmptyStateWidget(
                    message: "No data for selected month",
                    icon: Icons.bar_chart_outlined,
                  ),
                );
              }

              // Determine max Y for scaling
              double maxY = 0;
              for (var val in data.values) {
                if (val > maxY) maxY = val;
              }
              if (maxY == 0) maxY = 100;

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxY * 1.2, // Add some headroom
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${settingsController.currencySymbol.value}${rod.toY.toStringAsFixed(0)}',
                          TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Show typical dates: 1, 5, 10, 15, 20, 25, 30
                          final day = value.toInt();
                          if (day == 1 || day % 5 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '$day',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
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
                  barGroups: data.entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          color: theme.colorScheme.primary,
                          width: 6, // Slightly thinner for daily bars
                          borderRadius: BorderRadius.circular(2),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY * 1.2,
                            color: theme.canvasColor,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        if (controller.budgetForSelectedMonth <= 0) {
          return GestureDetector(
            onTap: () => _showEditBudgetDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set your monthly budget\nto get started',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Budget',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => _showEditBudgetDialog(context),
                    child: Text(
                      'Edit Budget →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final spent = controller.analyticsTotal;
                final budget = controller.budgetForSelectedMonth;
                final remaining = budget - spent;
                final progress = (spent / budget).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${settingsController.currencySymbol.value}${remaining.toStringAsFixed(0)} Remaining',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        // Large text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Spent ${settingsController.currencySymbol.value}${spent.toStringAsFixed(0)} of ${settingsController.currencySymbol.value}${budget.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: theme
                            .scaffoldBackgroundColor, // Or slightly darker/lighter than card
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFE57373); // Red
      case 'Travel':
        return const Color(0xFF64B5F6); // Blue
      case 'Shopping':
        return const Color(0xFFFFD54F); // Yellow
      case 'Bills':
        return const Color(0xFF81C784); // Green
      default:
        return AppColors.lightGrey;
    }
  }

  void _showEditBudgetDialog(BuildContext context) {
    final TextEditingController budgetController = TextEditingController(
      text: controller.budgetForSelectedMonth.toStringAsFixed(0),
    );

    Get.defaultDialog(
      title: 'Edit Monthly Budget',
      contentPadding: const EdgeInsets.all(16),
      content: TextField(
        controller: budgetController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Budget Amount',
          hintText: 'Enter amount',
          prefixText: '${settingsController.currencySymbol.value} ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        autofocus: true,
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        final amount = double.tryParse(budgetController.text);
        if (amount != null && amount >= 0) {
          Get.back(); // Close dialog first to avoid race conditions with Snackbars
          controller.setMonthlyBudget(amount);
        } else {
          Get.snackbar(
            'Error',
            'Please enter a valid amount (0 to clear)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
      },
    );
  }
}
