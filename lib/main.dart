import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CryptoRadarApp());
}

class CryptoRadarApp extends StatelessWidget {
  const CryptoRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Radar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.amber,
      ),
      home: const AuthGate(),
    );
  }
}

// بوابة التحقق من تسجيل الدخول
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }
        if (snapshot.hasData) {
          return const RadarHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// شاشة تسجيل الدخول عبر جوجل
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // إلغاء المستخدم لتسجيل الدخول
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تسجيل الدخول: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.radar, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                'Crypto Radar',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'سجّل الدخول باستخدام حساب جوجل للوصول إلى التحليلات',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.amber)
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                      ),
                      label: const Text(
                        'تسجيل الدخول عبر Google',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _signInWithGoogle,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// شاشة الرادار الرئيسية
class RadarHomeScreen extends StatefulWidget {
  const RadarHomeScreen({super.key});

  @override
  State<RadarHomeScreen> createState() => _RadarHomeScreenState();
}

class _RadarHomeScreenState extends State<RadarHomeScreen> {
  List<dynamic> _marketData = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => _fetchMarketData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMarketData() async {
    try {
      final response = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/24hr'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final filtered = data.where((item) => item['symbol'].toString().endsWith('USDT')).toList();
        setState(() {
          _marketData = filtered.take(20).toList();
          _loading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Radar Dashboard'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _signOut,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Column(
              children: [
                if (user != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF1E293B),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                          child: user.photoURL == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'مرحباً: ${user.displayName ?? user.email ?? ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _marketData.length,
                    itemBuilder: (context, index) {
                      final coin = _marketData[index];
                      final price = double.tryParse(coin['lastPrice'] ?? '0') ?? 0;
                      final change = double.tryParse(coin['priceChangePercent'] ?? '0') ?? 0;
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            coin['symbol'],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Text(
                            'الحجم: ${coin['volume']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$$price',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: change >= 0 ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
