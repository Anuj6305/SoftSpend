import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:softspend/views/dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Dashboard after 1.5 seconds to simulate splash delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.off(
        () => DashboardPage(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 800),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Consistent with native splash
      body: Center(child: Image.asset('assets/images/splash_logo.png')),
    );
  }
}
