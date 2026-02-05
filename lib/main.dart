import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:softspend/utils/app_colors.dart';
import 'package:softspend/controllers/settings_controller.dart';
import 'package:softspend/views/splash_screen.dart';

void main() async {
  await GetStorage.init('SoftSpend_v2');
  // Initialize SettingsController to load theme preference
  Get.put(SettingsController());
  runApp(const SoftSpendApp());
}

class SoftSpendApp extends StatelessWidget {
  const SoftSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      return GetMaterialApp(
        title: 'SoftSpend',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryText,
            primary: AppColors.primaryText,
            secondary: AppColors.accent,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: AppColors.primaryText),
          ),
        ),
        darkTheme: ThemeData(
          scaffoldBackgroundColor: AppColors.darkBackground,
          cardColor: AppColors.darkSurface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.white,
            primary: AppColors.darkPrimaryText,
            secondary: AppColors.darkAccent,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkPrimaryText,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.darkBackground,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: AppColors.darkPrimaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: AppColors.darkPrimaryText),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.darkPrimaryText),
            bodyMedium: TextStyle(color: AppColors.darkPrimaryText),
            bodySmall: TextStyle(color: AppColors.darkSecondaryText),
            titleLarge: TextStyle(
              color: AppColors.darkPrimaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.darkSecondaryText),
          // Ensure inputs are readable in dark mode
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.darkSurface,
            hintStyle: const TextStyle(color: AppColors.darkSecondaryText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: AppColors.darkSurface,
            modalBackgroundColor: AppColors.darkSurface,
          ),
        ),
        themeMode: settingsController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const SplashScreen(),
      );
    });
  }
}
