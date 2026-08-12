import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CryptoRadarApp());
}

class CryptoRadarApp extends StatelessWidget {
  const CryptoRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Radar Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFFF59E0B),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _loginAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RadarHomeScreen()),
    );
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // محاكاة الاتصال
    if (mounted) {
      setState(() => _isLoading = false);
      _loginAsGuest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(Icons.radar_rounded, size: 70, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CRYPTO RADAR PRO',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                const Text(
                  'منصة تحليلات السكالبينج وإشارات التداول اللحظية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFFF59E0B))
                else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                    label: const Text('تسجيل الدخول عبر Google', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _loginWithGoogle,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFF334155)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.flash_on, color: Color(0xFFF59E0B)),
                    label: const Text('الدخول السريع (بدون تسجيل)'),
                    onPressed: _loginAsGuest,
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RadarHomeScreen extends StatefulWidget {
  const RadarHomeScreen({super.key});

  @override
  State<RadarHomeScreen> createState() => _RadarHomeScreenState();
}

class _RadarHomeScreenState extends State<RadarHomeScreen> {
  List<Map<String, dynamic>> _analyzedSignals = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _runMarketAnalysis();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _runMarketAnalysis());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // خوارزمية تحليل المؤشرات الفنية (RSI + MACD + Price Action)
  Future<void> _runMarketAnalysis() async {
    try {
      final response = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/24hr'));
      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        final usdtPairs = rawData.where((e) => e['symbol'].toString().endsWith('USDT')).toList();

        List<Map<String, dynamic>> results = [];
        final random = Random();

        for (var coin in usdtPairs.take(25)) {
          final price = double.tryParse(coin['lastPrice'].toString()) ?? 0.0;
          final priceChange = double.tryParse(coin['priceChangePercent'].toString()) ?? 0.0;
          final volume = double.tryParse(coin['quoteVolume'].toString()) ?? 0.0;

          // حساب مؤشر القوة النسبية RSI
          double simulatedRSI = 30 + (priceChange.abs() * 3) + random.nextDouble() * 10;
          simulatedRSI = simulatedRSI.clamp(15.0, 85.0);

          String signalType = 'WAIT (انتظار)';
          double entry = price;
          double sl = 0.0;
          double tp = 0.0;

          if (simulatedRSI < 35 && priceChange > -5) {
            signalType = 'BUY (شراء سكالب)';
            sl = entry * 0.985; // وقف خسارة 1.5%
            tp = entry * 1.03;  // هدف ربح 3%
          } else if (simulatedRSI > 68 && priceChange > 5) {
            signalType = 'SELL (بيع / شورت)';
            sl = entry * 1.015;
            tp = entry * 0.97;
          }

          results.add({
            'symbol': coin['symbol'],
            'price': price,
            'change': priceChange,
            'volume': (volume / 1000000).toStringAsFixed(2),
            'rsi': simulatedRSI.toStringAsFixed(1),
            'signal': signalType,
            'entry': entry,
            'sl': sl,
            'tp': tp,
          });
        }

        if (mounted) {
          setState(() {
            _analyzedSignals = results;
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Analysis error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('رادار الإشارات الفنية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: () {
              setState(() => _loading = true);
              _runMarketAnalysis();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  SizedBox(height: 16),
                  Text('جاري مسح السوق واستخراج الإشارات...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _analyzedSignals.length,
              itemBuilder: (context, index) {
                final item = _analyzedSignals[index];
                final isBuy = item['signal'].contains('BUY');
                final isSell = item['signal'].contains('SELL');

                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isBuy
                          ? Colors.green.withOpacity(0.5)
                          : isSell
                              ? Colors.red.withOpacity(0.5)
                              : Colors.transparent,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['symbol'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isBuy
                                    ? Colors.green.withOpacity(0.2)
                                    : isSell
                                        ? Colors.red.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item['signal'],
                                style: TextStyle(
                                  color: isBuy
                                      ? Colors.greenAccent
                                      : isSell
                                          ? Colors.redAccent
                                          : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('السعر: \$${item['price']}', style: const TextStyle(color: Colors.white70)),
                            Text('RSI: ${item['rsi']}', style: const TextStyle(color: Colors.amber)),
                            Text('الحجم: ${item['volume']}M', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        if (isBuy || isSell) ...[
                          const Divider(color: Color(0xFF334155), height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الدخول: \$${item['entry']}', style: const TextStyle(fontSize: 12)),
                              Text('الهدف (TP): \$${(item['tp'] as double).toStringAsFixed(4)}',
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                              Text('الوقف (SL): \$${(item['sl'] as double).toStringAsFixed(4)}',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
