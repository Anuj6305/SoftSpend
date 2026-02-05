import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:softspend/models/expense_model.dart';
import 'package:softspend/controllers/settings_controller.dart';

class ExpenseController extends GetxController {
  // Reactive list of expenses
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  // Dashboard Tab State (0 = Transactions, 1 = Analytics)
  final RxInt currentTab = 0.obs;
  // Alert State
  final box = GetStorage('SoftSpend_v2');
  final settingsController = Get.find<SettingsController>();

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
  }

  void loadExpenses() {
    _checkMonthChange(); // Handle month transition first

    final storedExpenses = box.read<List>('expenses');

    // LOAD BUDGETS
    final storedBudgets = box.read<Map<String, dynamic>>('monthlyBudgets');

    if (storedBudgets != null) {
      // Cast to correct type
      monthlyBudgets.assignAll(
        storedBudgets.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );
    } else {
      // MIGRATION: Check for old single budget style
      final legacyBudget = box.read<double>('monthlyBudget');
      if (legacyBudget != null && legacyBudget > 0) {
        // Assign legacy budget to CURRENT month so user doesn't lose it
        monthlyBudgets[_currentMonthKey] = legacyBudget;
      }
    }

    if (storedExpenses != null && storedExpenses.isNotEmpty) {
      expenses.assignAll(
        storedExpenses.map((e) => ExpenseModel.fromJson(e)).toList(),
      );
    }

    // Check initial status without alerting to avoid spam on startup,
    // unless strictly required. User context implies "triggers when budget EXCEEDED".
    // We will initialize the flag based on current state to reset it if budget is positive.
    if ((budgetForCurrentMonth - totalForMonth) < 0 &&
        budgetForCurrentMonth > 0) {
      // If we load up and are already over budget, we trigger the alert.
      // Wrap in Future.microtask to prevent crash if called during build
      Future.microtask(() => checkBudgetStatus());
    }
  }

  void saveExpenses() {
    final expensesJson = expenses.map((e) => e.toJson()).toList();
    box.write('expenses', expensesJson);
    box.write('monthlyBudgets', monthlyBudgets);
  }

  // Get total expenses for the current month
  double get totalForMonth {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Get total by category
  double getTotalByCategory(String category) {
    return expenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  void addExpense({
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) {
    final newExpense = ExpenseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: (note != null && note.isNotEmpty) ? note : category,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );

    expenses.insert(0, newExpense); // Add to top of list
    saveExpenses(); // Persist data
    Get.back(); // Close bottom sheet

    checkBudgetStatus();
  }

  void updateExpense({
    required String id,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) {
    final index = expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      expenses[index] = ExpenseModel(
        id: id,
        title: (note != null && note.isNotEmpty) ? note : category,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      expenses.refresh(); // Refresh list to update UI
      saveExpenses(); // Persist data
      Get.back();
      checkBudgetStatus();
    }
  }

  // Filter State
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedDateFilter = 'This Month'.obs;

  // Analytics Filter
  final Rx<DateTime> selectedMonth = DateTime.now().obs;

  // Budget State
  // Budget State
  final RxMap<String, double> monthlyBudgets = <String, double>{}.obs;

  String get _currentMonthKey => _getMonthKey(DateTime.now());
  String get _selectedMonthKey => _getMonthKey(selectedMonth.value);

  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  double get budgetForSelectedMonth => monthlyBudgets[_selectedMonthKey] ?? 0.0;
  double get budgetForCurrentMonth => monthlyBudgets[_currentMonthKey] ?? 0.0;

  void setMonthlyBudget(double amount) {
    // Set budget for the SELECTED month
    monthlyBudgets[_selectedMonthKey] = amount;
    saveExpenses();

    // Check status if we edited CURRENT month
    if (_selectedMonthKey == _currentMonthKey) {
      checkBudgetStatus();
    }

    // Always show success for setting budget
    // Calculate remaining for selected month for feedback

    final remaining = amount - analyticsTotal;

    // If budget is 0 (cleared) or we are within budget, show success.
    // If we set a new budget and are ALREADY over it, checkBudgetStatus takes care of the warning (if budget > 0).
    if (remaining >= 0 || amount == 0) {
      Get.snackbar(
        'Success',
        'Budget updated!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void checkBudgetStatus() {
    // Only check for CURRENT month
    if (budgetForCurrentMonth <= 0) return;

    final remaining = budgetForCurrentMonth - totalForMonth;

    // Trigger logic: ALWAYS alert if remainingBudget < 0
    if (remaining < 0) {
      Get.closeAllSnackbars(); // Force close existing to show new one immediately
      Get.snackbar(
        'Budget Overspent',
        'You are overspent by ${settingsController.currencySymbol.value}${(-remaining).toStringAsFixed(0)}',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.amber[700], // Muted warning color as requested
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Analytics Helpers
  void changeMonth(int offset) {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + offset,
    );
  }

  // Analytics Data Selectors
  List<ExpenseModel> get analyticsExpenses {
    return expenses
        .where(
          (e) =>
              e.date.year == selectedMonth.value.year &&
              e.date.month == selectedMonth.value.month,
        )
        .toList();
  }

  double get analyticsTotal {
    return analyticsExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Filtered Expenses (Dashboard)
  List<ExpenseModel> get filteredExpenses {
    List<ExpenseModel> filtered = expenses;

    // 1. Filter by Category
    if (selectedCategory.value != 'All') {
      filtered = filtered
          .where((e) => e.category == selectedCategory.value)
          .toList();
    }

    // 2. Filter by Date
    final now = DateTime.now();
    if (selectedDateFilter.value == 'Today') {
      filtered = filtered
          .where(
            (e) =>
                e.date.year == now.year &&
                e.date.month == now.month &&
                e.date.day == now.day,
          )
          .toList();
    } else if (selectedDateFilter.value == 'This Week') {
      // Simple "last 7 days" or "current calendar week"?
      // User requirement says "This Week -> current week expenses".
      // Let's use simplified "start of week" logic or just last 7 days for simplicity if not strictly calendar week.
      // But typically "This Week" implies from Monday/Sunday to now.
      // Let's do: Find most recent Monday (or today if Monday) and filter from there.
      // Actually, let's keep it simple: "This Week" = in the same calendar week (Mon-Sun).

      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      // Reset time to 00:00:00
      final startOfWeekMidnight = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      filtered = filtered
          .where(
            (e) =>
                e.date.isAfter(startOfWeekMidnight) ||
                e.date.isAtSameMomentAs(startOfWeekMidnight),
          )
          .toList();
    } else if (selectedDateFilter.value == 'This Month') {
      filtered = filtered
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();
    }

    return filtered;
  }

  // Chart Data: Category Breakdown (For Analytics View)
  Map<String, double> get analyticsCategoryBreakdown {
    final Map<String, double> totals = {};
    for (var expense in analyticsExpenses) {
      if (!totals.containsKey(expense.category)) {
        totals[expense.category] = 0;
      }
      totals[expense.category] = totals[expense.category]! + expense.amount;
    }
    return totals;
  }

  // Chart Data: Time Breakdown (For Analytics View - Daily Trend)
  Map<int, double> get analyticsTimeBreakdown {
    final Map<int, double> totals = {};

    // Default to days in month
    final daysInMonth = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
      0,
    ).day;

    for (int i = 1; i <= daysInMonth; i++) totals[i] = 0;

    for (var expense in analyticsExpenses) {
      final day = expense.date.day;
      totals[day] = (totals[day] ?? 0) + expense.amount;
    }
    return totals;
  }

  // Chart Data: Category Breakdown (Dashboard - uses filteredExpenses)
  Map<String, double> get categoryBreakdown {
    final Map<String, double> totals = {};
    for (var expense in filteredExpenses) {
      if (!totals.containsKey(expense.category)) {
        totals[expense.category] = 0;
      }
      totals[expense.category] = totals[expense.category]! + expense.amount;
    }
    return totals;
  }

  // Chart Data: Time Breakdown (Dashboard - uses filteredExpenses)
  // Returns Map<int, double> where int is the x-axis index (Hour, Weekday, or Day)
  Map<int, double> get timeBreakdown {
    final Map<int, double> totals = {};
    final filter = selectedDateFilter.value;

    if (filter == 'Today') {
      // Group by Hour (0-23)
      // Initialize 0 for all hours (optional, but good for empty bars)
      for (int i = 0; i < 24; i++) totals[i] = 0;

      for (var expense in filteredExpenses) {
        final hour = expense.date.hour;
        totals[hour] = (totals[hour] ?? 0) + expense.amount;
      }
    } else if (filter == 'This Week') {
      // Group by Weekday (1=Mon, 7=Sun)
      for (int i = 1; i <= 7; i++) totals[i] = 0;

      for (var expense in filteredExpenses) {
        final weekday = expense.date.weekday;
        totals[weekday] = (totals[weekday] ?? 0) + expense.amount;
      }
    } else if (filter == 'This Month') {
      // Group by Day of Month (1-31)
      final daysInMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        0,
      ).day;
      for (int i = 1; i <= daysInMonth; i++) totals[i] = 0;

      for (var expense in filteredExpenses) {
        final day = expense.date.day;
        totals[day] = (totals[day] ?? 0) + expense.amount;
      }
    }
    return totals;
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    saveExpenses(); // Persist data
    checkBudgetStatus();
  }

  void clearAllExpenses() {
    expenses.clear();
    box.remove('expenses');
  }

  // Month Change Logic
  void _checkMonthChange() {
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final lastActiveMonth = box.read<String>('lastActiveMonth');

    if (lastActiveMonth != null && lastActiveMonth != currentMonthKey) {
      // Month has changed!
      // Note: totalForMonth automatically treats new month as 0 because it filters by now.month
      // Note: We do NOT delete expenses or budget as per rules.
    }

    // Update stored month to current
    box.write('lastActiveMonth', currentMonthKey);
  }
}
