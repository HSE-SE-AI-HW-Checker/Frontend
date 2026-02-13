import 'package:flutter/material.dart';
import 'screens/auth_page.dart';
import 'screens/main_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSValidator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4FF),
          secondary: Color(0xFF7C3AED),
          surface: Color(0xFF111827),
        ),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const Scaffold(
              backgroundColor: Color(0xFF0A0E1A),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00D4FF),
                ),
              ),
            )
          : _isAuthenticated
              ? const MainPage()
              : const AuthPage(),
    );
  }
}
