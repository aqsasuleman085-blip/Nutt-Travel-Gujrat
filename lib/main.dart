import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutt/admin_side/core/constants/app_constants.dart';
import 'package:nutt/admin_side/providers/auth_provider.dart';
import 'package:nutt/admin_side/providers/booking_provider.dart';
import 'package:nutt/admin_side/providers/bus_provider.dart';
import 'package:nutt/admin_side/providers/dashboard_provider.dart';
import 'package:nutt/admin_side/providers/notification_provider.dart';
import 'package:nutt/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
//file
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB7EuxWgstYll8_IeYMObk-Py9UkUvQvHc",
        authDomain: "nutt-setup.firebaseapp.com",
        projectId: "nutt-setup",
        storageBucket: "nutt-setup.firebasestorage.app",
        messagingSenderId: "788481227164",
        appId: "1:788481227164:web:e4fca5b41e40ff89a7b059",
      ),
    );
  } else {
   await Firebase.initializeApp();
  }

  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => BusProvider(prefs)),
        ChangeNotifierProvider(create: (_) => BookingProvider(prefs)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(prefs)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(prefs)),
      ],
      child: MaterialApp(
        title: 'Bus Management System',
        debugShowCheckedModeBanner: false,
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
        home: const WelcomeScreen(),
      ),
    );
  }
}