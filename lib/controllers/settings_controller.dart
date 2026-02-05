import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final box = GetStorage();

  // Observable State
  final RxString currencySymbol = '₹'.obs;
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    // Load Currency
    final savedCurrency = box.read<String>('currency');
    if (savedCurrency != null) {
      currencySymbol.value = savedCurrency;
    }

    // Load Theme
    final savedThemeInfo = box.read<bool>('isDarkMode');
    if (savedThemeInfo != null) {
      isDarkMode.value = savedThemeInfo;
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    }
  }

  void setCurrency(String symbol) {
    currencySymbol.value = symbol;
    box.write('currency', symbol);
  }

  void toggleTheme(bool isDark) {
    isDarkMode.value = isDark;
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    box.write('isDarkMode', isDark);
  }
}
