import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const OtimusicApp());
}

class OtimusicApp extends StatefulWidget {
  const OtimusicApp({super.key});

  @override
  State<OtimusicApp> createState() => _OtimusicAppState();
}

class _OtimusicAppState extends State<OtimusicApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 检查登录状态
  Future<void> _checkLoginStatus() async {
    final loginInfo = await StorageService.getLoginInfo();
    setState(() {
      _isLoggedIn = loginInfo != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 加载状态显示进度指示器
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Otimusic',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      // 根据登录状态决定初始页面
      home: _isLoggedIn ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
