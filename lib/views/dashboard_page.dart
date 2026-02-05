import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:softspend/controllers/expense_controller.dart';
import 'package:softspend/models/expense_model.dart';
import 'package:softspend/utils/app_colors.dart';
import 'package:softspend/views/analytics_view.dart';
import 'package:softspend/controllers/settings_controller.dart';
import 'package:softspend/views/settings_page.dart';
import 'package:softspend/utils/ui_helpers.dart';

class DashboardPage extends StatelessWidget {
  final ExpenseController controller = Get.put(ExpenseController());
  final SettingsController settingsController = Get.put(SettingsController());

  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                // Show Summary only on Transactions tab
                if (controller.currentTab.value == 0) ...[
                  _buildMonthlySummary(context),
                  const SizedBox(height: 32),
                  _buildCategoryOverview(context),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildExpenseList(context)),
                ] else ...[
                  // Analytics View
                  Expanded(child: AnalyticsView()),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.bottomSheet(
            const _ExpenseBottomSheet(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
        backgroundColor: AppColors.primaryText,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SoftSpend',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        // Custom Tab Switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              _buildTabButton(context, 'List', 0),
              _buildTabButton(context, 'Analytics', 1),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.to(() => SettingsPage()),
          icon: Icon(Icons.settings, color: theme.iconTheme.color),
        ),
      ],
    );
  }

  Widget _buildTabButton(BuildContext context, String text, int index) {
    final theme = Theme.of(context);
    return Obx(() {
      final isSelected = controller.currentTab.value == index;
      return GestureDetector(
        onTap: () {
          lightHaptic();
          controller.currentTab.value = index;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMonthlySummary(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'This Month',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => CountUpText(
              value: controller.totalForMonth,
              prefix: settingsController.currencySymbol.value,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOverview(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Date Filter
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['Today', 'This Week', 'This Month'].map((filter) {
              return Obx(() {
                final isSelected =
                    controller.selectedDateFilter.value == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        lightHaptic();
                        controller.selectedDateFilter.value = filter;
                      }
                    },
                    backgroundColor: theme.cardColor,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              });
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Category Filter
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['All', 'Food', 'Travel', 'Shopping', 'Bills'].map((
              category,
            ) {
              return Obx(() {
                final isSelected =
                    controller.selectedCategory.value == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        lightHaptic();
                        controller.selectedCategory.value = category;
                      }
                    },
                    backgroundColor: theme.cardColor,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              });
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseList(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.filteredExpenses.isEmpty) {
        return GestureDetector(
          onTap: () {
            Get.bottomSheet(
              const _ExpenseBottomSheet(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
          child: const FadeInSlide(
            child: EmptyStateWidget(
              message: 'No expenses yet\nTap here to add',
              icon: Icons.add_circle_outline,
            ),
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: false, // Ensure it takes available space
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: controller.filteredExpenses.length,
        itemBuilder: (context, index) {
          final expense = controller.filteredExpenses[index];
          return FadeInSlide(
            key: ValueKey(expense.id), // Key helps with reordering animations
            delay: index * 0.05, // Staggered animation
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.canvasColor, // Subtle contrast
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForCategory(expense.category),
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(expense.date),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-${settingsController.currencySymbol.value}${expense.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                    color: theme.cardColor,
                    onSelected: (value) {
                      if (value == 'edit') {
                        Get.bottomSheet(
                          _ExpenseBottomSheet(expense: expense),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );
                      } else if (value == 'delete') {
                        Get.defaultDialog(
                          title: 'Delete Expense',
                          middleText:
                              'Are you sure you want to delete this expense?',
                          textConfirm: 'Delete',
                          textCancel: 'Cancel',
                          confirmTextColor: Colors.white,
                          buttonColor: Colors.redAccent,
                          backgroundColor: theme.cardColor,
                          titleStyle: theme.textTheme.titleLarge,
                          middleTextStyle: theme.textTheme.bodyMedium,
                          onConfirm: () {
                            controller.deleteExpense(expense.id);
                            Get.back();
                          },
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 8),
                                Text('Edit', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Travel':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.attach_money;
    }
  }
}

class _ExpenseBottomSheet extends StatefulWidget {
  final ExpenseModel? expense;

  const _ExpenseBottomSheet({this.expense});

  @override
  State<_ExpenseBottomSheet> createState() => _ExpenseBottomSheetState();
}

class _ExpenseBottomSheetState extends State<_ExpenseBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Local temporary state variables
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final ExpenseController _controller = Get.find<ExpenseController>();
  final SettingsController _settingsController = Get.find<SettingsController>();

  final List<String> _categories = ['Food', 'Travel', 'Shopping', 'Bills'];

  @override
  void initState() {
    super.initState();
    // 1. Initialize local state from existing expense if editing
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _noteController.text = widget.expense!.note ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter an amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Error',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // 3. Save Logic: Update Controller ONLY here (Single Save Point)
    if (widget.expense != null) {
      _controller.updateExpense(
        id: widget.expense!.id,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim(),
      );
    } else {
      _controller.addExpense(
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim(),
      );
    }

    // 4. Close the sheet is handled by controller
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryText,
              onPrimary: AppColors.white,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final theme = Theme.of(context);
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.expense != null
                                  ? 'Edit Expense'
                                  : 'Add Expense',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: Icon(
                                Icons.close,
                                color: theme.iconTheme.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Amount Input
                        Text(
                          'AMOUNT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary, // Make amount pop
                          ),
                          decoration: InputDecoration(
                            prefixText:
                                '${_settingsController.currencySymbol.value} ',
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                            fillColor: Colors
                                .transparent, // Transparent for cleaner look
                          ),
                        ),
                        Divider(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 24),

                        // Category Selector
                        Text(
                          'CATEGORY',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.cardColor,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : theme.dividerColor.withValues(
                                          alpha: 0.1,
                                        ),
                                ),
                              ),
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Date Picker
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: theme.cardColor,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'EEEE, MMM d, y',
                                  ).format(_selectedDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Note Input
                        TextField(
                          controller: _noteController,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Add a note (optional)',
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _saveExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.expense != null
                                  ? 'Update Expense'
                                  : 'Save Expense',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
