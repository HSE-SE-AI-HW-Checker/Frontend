import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/room.dart';
import '../services/room_service.dart';
import 'create_room_page.dart';
import 'manage_room_page.dart';
import 'room_page.dart';

const _accentPrimary = Color(0xFF00D4FF);
const _accentSecondary = Color(0xFF7C3AED);
const _textPrimary = Color(0xFFF9FAFB);
const _textSecondary = Color(0xFF9CA3AF);
const _borderColor = Color(0x3300D4FF);
const _bgCard = Color(0x99111827);
const _success = Color(0xFF10B981);

class RoomsPage extends StatefulWidget {
  final VoidCallback? onRecentRoomsRefreshNeeded;

  const RoomsPage({super.key, this.onRecentRoomsRefreshNeeded});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late PageController _pageController;
  int _currentTab = 0;
  final _roomIdController = TextEditingController();
  final _passwordController = TextEditingController();

  final _roomService = RoomService();
  List<Room> _myRooms = [];
  bool _isLoadingRooms = true;
  String? _roomsErrorMessage;
  bool _isJoining = false;
  String? _joinError;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pageController = PageController();
    _loadMyRooms();
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isJoining = true;
      _joinError = null;
    });

    try {
      await _roomService.joinRoom(roomId, password);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoomPage(roomId: roomId),
        ),
      );
      widget.onRecentRoomsRefreshNeeded?.call();
      _loadMyRooms();
    } catch (_) {
      if (mounted) {
        setState(() => _joinError = 'Неправильный логин комнаты или пароль');
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _loadMyRooms() async {
    try {
      final rooms = await _roomService.getMyRooms();
      if (mounted) {
        setState(() {
          _myRooms = rooms;
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _roomsErrorMessage = e.toString();
          _isLoadingRooms = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController.dispose();
    _roomIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'Неизвестно';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _onTabChanged(int index) {
    setState(() => _currentTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(_bgController.value * 2 * pi),
                );
              },
            ),
          ),

          // Grid
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                _buildTabs(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildJoinTab(),
                      _buildMyRoomsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Комнаты',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Подключайтесь или создавайте свои',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _tab(0, 'Подключиться')),
          const SizedBox(width: 8),
          Expanded(child: _tab(1, 'Мои комнаты')),
        ],
      ),
    );
  }

  Widget _tab(int index, String label) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? _accentPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? _accentPrimary : _textSecondary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 6),
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _accentPrimary,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 105),
      children: [
        // Join Card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentPrimary, _accentSecondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.login,
                  size: 32,
                  color: Colors.white,
                ),
              ),

              const Text(
                'Войти в комнату',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Введите ID комнаты и пароль, полученные от организатора',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),

              // Room ID Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ID комнаты',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _roomIdController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.firaCode(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                    maxLength: 14,
                    decoration: InputDecoration(
                      hintText: 'XXXX-XXXX-XXXX',
                      hintStyle: TextStyle(
                        color: _textSecondary.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: const Color(0x801F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _accentPrimary,
                          width: 1.5,
                        ),
                      ),
                      counterText: '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Password Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Пароль',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Введите пароль',
                      hintStyle: TextStyle(
                        color: _textSecondary.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: const Color(0x801F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _accentPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Join error
              if (_joinError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _joinError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Join Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [_accentPrimary, _accentSecondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isJoining ? null : _joinRoom,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: _isJoining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Подключиться',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info Block
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accentPrimary.withValues(alpha: 0.05),
            border: Border.all(color: _accentPrimary.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: _accentPrimary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'После подключения вы получите доступ к заданиям и сможете отправлять решения на проверку',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyRoomsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // Create Button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _accentPrimary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateRoomPage(),
                  ),
                );
                _loadMyRooms();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: _accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Создать комнату',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Rooms List
        if (_isLoadingRooms)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentPrimary),
              ),
            ),
          )
        else if (_roomsErrorMessage != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Ошибка загрузки комнат',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _roomsErrorMessage!,
                  style: const TextStyle(color: _textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_myRooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: const Center(
              child: Text(
                'У вас пока нет комнат',
                style: TextStyle(color: _textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._myRooms.map((room) => _buildRoomItem(room)),
      ],
    );
  }

  Widget _buildRoomItem(Room room) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoomPage(roomId: room.id)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ${room.id}',
                        style: GoogleFonts.firaCode(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (room.isActive ?? false)
                      ? _success.withValues(alpha: 0.15)
                      : _textSecondary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: (room.isActive ?? false)
                        ? _success.withValues(alpha: 0.3)
                        : _textSecondary.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (room.isActive ?? false) ? 'АКТИВНА' : 'АРХИВ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: (room.isActive ?? false) ? _success : _textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManageRoomPage(roomId: room.id),
                    ),
                  );
                  widget.onRecentRoomsRefreshNeeded?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 16,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 14,
                color: _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${room.participants} участников',
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(room.created),
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// Background painters
class _BackgroundPainter extends CustomPainter {
  final double rotation;
  _BackgroundPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width, -size.height);

    final purpleCenter = Offset(size.width * 0.4, size.height);
    canvas.drawCircle(
      purpleCenter,
      size.width * 0.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(
            Rect.fromCircle(center: purpleCenter, radius: size.width * 0.8)),
    );

    final cyanCenter = Offset(size.width * 1.6, size.height * 1.6);
    canvas.drawCircle(
      cyanCenter,
      size.width * 0.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00D4FF).withValues(alpha: 0.15),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _accentPrimary.withValues(alpha: 0.03)
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
