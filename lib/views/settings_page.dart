import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:softspend/controllers/expense_controller.dart';
import 'package:softspend/controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  final SettingsController settingsController = Get.find<SettingsController>();
  final ExpenseController expenseController = Get.find<ExpenseController>();

  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Preferences'),
            const SizedBox(height: 16),
            _buildCurrencyParams(context),
            const SizedBox(height: 24),
            _buildThemeSwitch(context),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Data'),
            const SizedBox(height: 16),
            _buildClearDataButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCurrencyParams(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currency',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              children: [
                _buildCurrencyOption(context, 'Rupee (₹)', '₹'),
                const SizedBox(width: 12),
                _buildCurrencyOption(context, 'Dollar (\$)', '\$'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context,
    String label,
    String symbol,
  ) {
    final theme = Theme.of(context);
    final isSelected = settingsController.currencySymbol.value == symbol;
    return Expanded(
      child: GestureDetector(
        onTap: () => settingsController.setCurrency(symbol),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Dark Mode',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Obx(
            () => Switch(
              value: settingsController.isDarkMode.value,
              onChanged: (value) => settingsController.toggleTheme(value),
              activeTrackColor: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Get.defaultDialog(
            title: 'Clear All Data',
            middleText: 'Are you sure? This cannot be undone.',
            textConfirm: 'Clear',
            textCancel: 'Cancel',
            confirmTextColor: Colors.white,
            buttonColor: Colors.redAccent,
            onConfirm: () {
              expenseController.clearAllExpenses();
              Get.back();
              Get.snackbar(
                'Success',
                'All data cleared',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Clear All Expenses',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
