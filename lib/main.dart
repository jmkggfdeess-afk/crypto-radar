import 'package:flutter/material.dart';

void main() => runApp(const CryptoApp());

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, size: 100, color: Colors.tealAccent),
            const SizedBox(height: 20),
            const Text("Crypto Radar", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _loginButton("Google", Colors.red, () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RadarScreen()));
            }),
            const SizedBox(height: 20),
            _loginButton("Facebook", Colors.blue, () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RadarScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _loginButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.all(15)),
        onPressed: onPressed,
        child: Text("Login with $text", style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("جاري مسح أزواج التداول على منصة Binance...", style: TextStyle(fontSize: 16, color: Colors.tealAccent)),
          const SizedBox(height: 10),
          const Text("سيتم إرسال الإشارة فور اكتشاف الفرصة", style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 50),
          Center(
            child: RotationTransition(
              turns: _controller,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [Colors.tealAccent.withOpacity(0.6), Colors.transparent]),
                  border: Border.all(color: Colors.tealAccent, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
