import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

const _accentPrimary = Color(0xFF00D4FF);
const _accentSecondary = Color(0xFF7C3AED);
const _textPrimary = Color(0xFFF9FAFB);
const _textSecondary = Color(0xFF9CA3AF);
const _inputBg = Color(0x801F2937);
const _borderColor = Color(0x3300D4FF);
const _cardBg = Color(0x99111827);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  late AnimationController _bgController;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (message.length > 100) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isError ? 'Ошибка' : 'Успех'),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      Map<String, dynamic> result;
      if (_isLogin) {
        result = await _authService.login(email, password);
      } else {
        result = await _authService.register(username, email, password);
      }

      if (!mounted) return;

      final message = result['message'] ??
          (_isLogin ? 'Успешный вход!' : 'Регистрация успешна!');
      final isError = result['error'] ?? false;

      _showMessage(message, isError: isError);

      if (!isError) {
        // TODO: Navigate to home page
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String placeholder) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
      filled: true,
      fillColor: _inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Animated rotating background gradients
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter:
                      _BackgroundPainter(_bgController.value * 2 * pi),
                );
              },
            ),
          ),

          // Grid overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                  )),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildAuthCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_accentPrimary, _accentSecondary],
            ).createShader(bounds),
            child: Text(
              'TSValidator',
              style: GoogleFonts.orbitron(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SECURE AUTH',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.25, 0.8, curve: Curves.easeOut),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.25, 0.8, curve: Curves.easeOut),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_isLogin)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _toggleForm,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _borderColor),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: _textSecondary,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isLogin ? 'Вход в систему' : 'Регистрация',
                            key: ValueKey(_isLogin),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    ..._buildFormFields(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    const SizedBox(height: 32),
                    _buildDivider(),
                    const SizedBox(height: 32),
                    _buildGoogleButton(),
                    const SizedBox(height: 24),
                    _buildToggleLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    return [
      _buildFieldLabel('Логин'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _isLogin ? _emailController : _usernameController,
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: _inputDecoration('Введите логин'),
        enabled: !_isLoading,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Введите логин';
          return null;
        },
      ),
      if (!_isLogin) ...[
        const SizedBox(height: 20),
        _buildFieldLabel('Email'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: _inputDecoration('Введите email'),
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Введите email';
            if (!value.contains('@')) return 'Введите корректный email';
            return null;
          },
        ),
      ],
      const SizedBox(height: 20),
      _buildFieldLabel('Пароль'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _passwordController,
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: _inputDecoration('Введите пароль'),
        obscureText: true,
        enabled: !_isLoading,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Введите пароль';
          if (value.length < 6) {
            return 'Пароль должен содержать минимум 6 символов';
          }
          return null;
        },
      ),
      if (!_isLogin) ...[
        const SizedBox(height: 20),
        _buildFieldLabel('Подтвердите пароль'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: _inputDecoration('Подтвердите пароль'),
          obscureText: true,
          enabled: !_isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Подтвердите пароль';
            if (value != _passwordController.text) {
              return 'Пароли не совпадают';
            }
            return null;
          },
        ),
      ],
    ];
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: _textSecondary,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accentPrimary, _accentSecondary],
        ),
        boxShadow: [
          BoxShadow(
            color: _accentPrimary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isLogin ? 'Войти' : 'Зарегистрироваться',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _borderColor, Colors.transparent],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ИЛИ',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _borderColor, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Google sign-in
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: _GoogleIconPainter()),
              ),
              const SizedBox(width: 12),
              const Text(
                'Войти через Google',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleLink() {
    return Center(
      child: GestureDetector(
        onTap: _isLoading ? null : _toggleForm,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: _textSecondary),
            children: [
              TextSpan(
                text: _isLogin ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ',
              ),
              TextSpan(
                text: _isLogin ? 'Регистрация' : 'Войти',
                style: const TextStyle(
                  color: _accentPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated background with rotating radial gradients
class _BackgroundPainter extends CustomPainter {
  final double rotation;

  _BackgroundPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width, -size.height);

    final fullRect = Rect.fromLTWH(0, 0, size.width * 2, size.height * 2);

    // Purple glow at ~20% 50%
    final purpleCenter = Offset(size.width * 0.4, size.height);
    canvas.drawCircle(
      purpleCenter,
      size.width * 0.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(
            Rect.fromCircle(center: purpleCenter, radius: size.width * 0.8)),
    );

    // Cyan glow at ~80% 80%
    final cyanCenter = Offset(size.width * 1.6, size.height * 1.6);
    canvas.drawCircle(
      cyanCenter,
      size.width * 0.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(
            Rect.fromCircle(center: cyanCenter, radius: size.width * 0.8)),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.rotation != rotation;
}

// Grid pattern overlay
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _accentPrimary.withOpacity(0.03)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Google logo icon painter (SVG paths converted to Flutter)
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale, scale);

    // Blue
    canvas.drawPath(
      Path()
        ..moveTo(22.56, 12.25)
        ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10)
        ..lineTo(12, 10)
        ..lineTo(12, 14.26)
        ..lineTo(17.92, 14.26)
        ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
        ..lineTo(15.71, 20.34)
        ..lineTo(19.28, 20.34)
        ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
        ..close(),
      Paint()..color = const Color(0xFF4285F4),
    );

    // Green
    canvas.drawPath(
      Path()
        ..moveTo(12, 23)
        ..cubicTo(14.97, 23, 17.46, 22.02, 19.28, 20.34)
        ..lineTo(15.71, 17.57)
        ..cubicTo(14.73, 18.23, 13.48, 18.63, 12, 18.63)
        ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
        ..lineTo(2.18, 14.1)
        ..lineTo(2.18, 16.94)
        ..cubicTo(3.99, 20.53, 7.7, 23, 12, 23)
        ..close(),
      Paint()..color = const Color(0xFF34A853),
    );

    // Yellow
    canvas.drawPath(
      Path()
        ..moveTo(5.84, 14.09)
        ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12)
        ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
        ..lineTo(5.84, 7.07)
        ..lineTo(2.18, 7.07)
        ..cubicTo(1.43, 8.55, 1, 10.22, 1, 12)
        ..cubicTo(1, 13.78, 1.43, 15.45, 2.18, 16.93)
        ..lineTo(5.03, 14.71)
        ..lineTo(5.84, 14.09)
        ..close(),
      Paint()..color = const Color(0xFFFBBC05),
    );

    // Red
    canvas.drawPath(
      Path()
        ..moveTo(12, 5.38)
        ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
        ..lineTo(19.36, 3.87)
        ..cubicTo(17.45, 2.09, 14.97, 1, 12, 1)
        ..cubicTo(7.7, 1, 3.99, 3.47, 2.18, 7.07)
        ..lineTo(5.84, 9.91)
        ..cubicTo(6.71, 7.31, 9.14, 5.38, 12, 5.38)
        ..close(),
      Paint()..color = const Color(0xFFEA4335),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
