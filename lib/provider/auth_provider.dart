import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uasppb_2021130024/screens/admin_screen.dart';
import 'package:uasppb_2021130024/screens/login_screen.dart';
import 'package:uasppb_2021130024/screens/upcoming_events.dart';

class AuthWrapper extends StatelessWidget {
  Future<String?> _getUserRole(String uid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc['role'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: _getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (roleSnapshot.hasData) {
                final role = roleSnapshot.data;
                if (role == 'admin') {
                  return AdminScreen(); // Navigate to admin screen
                } else {
                  return UpcomingEventsScreen(); // Navigate to user screen
                }
              } else {
                return LoginScreen();
              }
            },
          );
        } else {
          return LoginScreen();
        }
      },
    );
  }
}