import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:uasppb_2021130024/main.dart';
import 'package:uasppb_2021130024/provider/auth_provider.dart';
import 'package:uasppb_2021130024/provider/theme_provider.dart';
import 'package:uasppb_2021130024/screens/admin_screen.dart';
import 'package:uasppb_2021130024/screens/upcoming_events.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Dicoding Events',
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Colors.white,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                color: Colors.white,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black54),
                displayLarge:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                titleLarge: TextStyle(color: Colors.black, fontSize: 18),
              ),
              buttonTheme: const ButtonThemeData(
                buttonColor: Colors.black,
                textTheme: ButtonTextTheme.primary,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              dividerColor: Colors.grey[300],
              cardTheme: CardTheme(
                color: Colors.white,
                shadowColor: Colors.grey[200],
                elevation: 4,
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.black,
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                color: Colors.black,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
                displayLarge:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                titleLarge: TextStyle(color: Colors.white, fontSize: 18),
              ),
              buttonTheme: const ButtonThemeData(
                buttonColor: Colors.white,
                textTheme: ButtonTextTheme.primary,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              dividerColor: Colors.grey[800],
              cardTheme: CardTheme(
                color: Colors.grey[900],
                shadowColor: Colors.grey[700],
                elevation: 4,
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode, // Dynamic theme mode
            home: AuthWrapper(),
          );
        },
      ),
    );
  }
}