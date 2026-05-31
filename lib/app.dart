import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/ui/admin/admin_shell.dart';
import 'package:daily_fitness/ui/auth/buyer_register_page.dart';
import 'package:daily_fitness/ui/auth/login_page.dart';
import 'package:daily_fitness/ui/auth/register_page.dart';
import 'package:daily_fitness/ui/auth/rider_register_page.dart';
import 'package:daily_fitness/ui/auth/seller_register_page.dart';
import 'package:daily_fitness/ui/buyer/buyer_shell.dart';
import 'package:daily_fitness/ui/guest/guest_shell.dart';
import 'package:daily_fitness/ui/rider/rider_shell.dart';
import 'package:daily_fitness/ui/seller/seller_shell.dart';
import 'package:daily_fitness/ui/shared/guest_page.dart';
import 'package:daily_fitness/ui/shared/splash_screen.dart';
import 'package:daily_fitness/ui/shared/theme_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DailyFitnessApp extends StatelessWidget {
  const DailyFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: MaterialApp(
        title: 'Daily Fitness',
        theme: ThemePalette.theme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/register/buyer': (context) => const BuyerRegisterPage(),
          '/register/seller': (context) => const SellerRegisterPage(),
          '/register/rider': (context) => const RiderRegisterPage(),
          '/guest': (context) => const GuestPage(),
          '/guest/browse': (context) => const GuestShell(),
          '/dashboard/buyer': (context) => const BuyerShell(),
          '/dashboard/seller': (context) => const SellerDashboard(),
          '/dashboard/rider': (context) => const RiderDashboard(),
          '/dashboard/admin': (context) => const AdminDashboard(),
        },
      ),
    );
  }
}
