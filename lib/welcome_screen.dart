  // welcome_screen.dart
  import 'package:flutter/material.dart';
  import 'login_screen.dart';

  class WelcomeScreen extends StatelessWidget {
    const WelcomeScreen({super.key});
    @override
    Widget build(BuildContext c) => Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/logo.png', height: 120),
                const SizedBox(height: 24),
                const Text('Welcome to MemeBoard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                  child: const Text('Get Started'),
                  onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const LoginScreen())),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
