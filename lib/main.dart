import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutt/admin_side/core/constants/app_constants.dart';
import 'package:nutt/admin_side/providers/auth_provider.dart';
import 'package:nutt/admin_side/providers/booking_provider.dart';
import 'package:nutt/admin_side/providers/bus_provider.dart';
import 'package:nutt/admin_side/providers/dashboard_provider.dart';
import 'package:nutt/admin_side/providers/broadcast_provider.dart';
import 'package:nutt/admin_side/providers/notification_provider.dart';
import 'package:nutt/admin_side/providers/theme_provider.dart';
import 'package:nutt/firebase_options.dart';
import 'package:nutt/splash_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BroadcastProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Bus Management System',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              primarySwatch: Colors.green,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeProvider.darkTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

