import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/app_user.dart';
import 'package:daily_fitness/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SessionProvider extends ChangeNotifier {
  AppUser? currentUser;
  bool isLoading = true;

  SessionProvider() {
    _listenToAuthState();
  }

  void _listenToAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (snapshot.exists) {
            currentUser = AppUser.fromMap(snapshot.data()! as Map<String, dynamic>);
          } else {
            currentUser = AppUser(
              uid: user.uid,
              role: 'buyer',
              firstName: user.displayName?.split(' ').first ?? 'Guest',
              lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
              username: user.email?.split('@').first ?? 'guest',
              email: user.email ?? '',
              phoneNumber: user.phoneNumber ?? '',
              profileImage: user.photoURL ?? '',
              status: 'active',
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
            );
          }
        } on FirebaseException catch (_) {
          currentUser = AppUser(
            uid: user.uid,
            role: 'buyer',
            firstName: user.displayName?.split(' ').first ?? 'Guest',
            lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
            username: user.email?.split('@').first ?? 'guest',
            email: user.email ?? '',
            phoneNumber: user.phoneNumber ?? '',
            profileImage: user.photoURL ?? '',
            status: 'active',
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          );
        }
      } else {
        currentUser = null;
      }
      isLoading = false;
      notifyListeners();
    });
  }

  bool get isAuthenticated => currentUser != null;

  String get dashboardRoute {
    if (currentUser == null) return '/login';
    // Block pending/declined/suspended sellers and riders
    if ((currentUser!.role == 'seller' || currentUser!.role == 'rider') &&
        currentUser!.status != 'active' && currentUser!.status != 'approved') {
      return '/login';
    }
    switch (currentUser!.role) {
      case 'seller':
        return '/dashboard/seller';
      case 'rider':
        return '/dashboard/rider';
      case 'admin':
        return '/dashboard/admin';
      default:
        return '/dashboard/buyer';
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    currentUser = null;
    notifyListeners();
  }
}
