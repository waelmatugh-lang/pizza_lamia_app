import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';
import '../auth/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Check auth state
    final user = Supabase.instance.client.auth.currentUser;

    if (!mounted) return;

    if (user != null) {
      // User is logged in, go to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // User is not logged in, go to AuthScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep Black
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              height: 120,
              width: 120,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon in case the image fails to load during dev
                return const Icon(
                  Icons.local_pizza,
                  size: 120,
                  color: Color(0xFFFF5722),
                );
              },
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'Pizza Lamia',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
            ),
          ],
        ),
      ),
    );
  }
}
