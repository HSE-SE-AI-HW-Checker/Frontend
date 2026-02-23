import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/room.dart';
import '../services/room_service.dart';
import 'profile_page.dart';
import 'room_page.dart';
import 'rooms_page.dart';

const _accentPrimary = Color(0xFF00D4FF);
const _accentSecondary = Color(0xFF7C3AED);
const _textPrimary = Color(0xFFF9FAFB);
const _textSecondary = Color(0xFF9CA3AF);
const _borderColor = Color(0x3300D4FF);
const _bgCard = Color(0x99111827);

const _colorLow = Color(0xFFEF4444);
const _colorMedium = Color(0xFFF59E0B);
const _colorHigh = Color(0xFF10B981);

Color _scoreColor(int score) {
  if (score >= 80) return _colorHigh;
  if (score >= 60) return _colorMedium;
  return _colorLow;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _currentNavIndex = 0;

  late AnimationController _bgController;
  late AnimationController _entryController;

  final _roomService = RoomService();
  List<Room> _recentRooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _loadRecentRooms();
  }

  Future<void> _loadRecentRooms() async {
    try {
      final rooms = await _roomService.getRecentRooms();
      if (mounted) {
        setState(() {
          _recentRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
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
            child: IndexedStack(
              index: _currentNavIndex,
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    _buildPageTitle(),
                    Expanded(child: _buildContent()),
                  ],
                ),
                const RoomsPage(),
                const ProfilePage(),
              ],
            ),
          ),

          // Bottom nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1A).withValues(alpha: 0.8),
            border: const Border(
              bottom: BorderSide(color: _borderColor, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accentPrimary, _accentSecondary],
                  ),
                  border: Border.all(color: _borderColor, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'IK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Недавние',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Последние посещенные комнаты',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentPrimary),
        ),
      );
    }

    if (_errorMessage != null || _recentRooms.isEmpty) {
      return const Center(
        child: Text(
          'Комнаты не найдены',
          style: TextStyle(color: _textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _recentRooms.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _entryController,
            curve: Interval(
              (0.2 + index * 0.08).clamp(0.0, 0.7),
              (0.5 + index * 0.08).clamp(0.3, 1.0),
              curve: Curves.easeOut,
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _entryController,
              curve: Interval(
                (0.2 + index * 0.08).clamp(0.0, 0.7),
                (0.5 + index * 0.08).clamp(0.3, 1.0),
                curve: Curves.easeOut,
              ),
            )),
            child: _RoomCard(room: _recentRooms[index]),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
        )),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1A).withValues(alpha: 0.95),
            border: const Border(
              top: BorderSide(color: _borderColor, width: 1),
            ),
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 16, left: 20, right: 20),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.verified_user_outlined, 'Недавние'),
                _navItem(1, Icons.grid_view_rounded, 'Комнаты'),
                _navItem(2, Icons.person_outline, 'Профиль'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              width: 40,
              height: 3,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [_accentPrimary, _accentSecondary],
                ),
              ),
            )
          else
            const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? _accentPrimary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? _accentPrimary : _textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isActive ? _accentPrimary : _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Room card ---

class _RoomCard extends StatefulWidget {
  final Room room;
  const _RoomCard({required this.room});

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final score = room.userScore ?? 0;
    final color = _scoreColor(score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RoomPage(roomName: room.name),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(_hovered ? 4 : 0, 0, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered ? _accentPrimary : _borderColor,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Left accent bar on hover
                if (_hovered)
                  Positioned(
                    left: -20,
                    top: -20,
                    bottom: -20,
                    child: Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_accentPrimary, _accentSecondary],
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Room header
                          Row(
                            children: [
                              _PulsingDot(color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  room.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Meta
                          Row(
                            children: [
                              _metaItem(Icons.people_outline, '${room.participants}'),
                              const SizedBox(width: 16),
                              _metaItem(Icons.access_time, room.lastActive ?? 'Неизвестно'),
                              const SizedBox(width: 16),
                              _metaItem(Icons.show_chart, '${room.submissions ?? 0}'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Score bar
                          _ScoreBar(score: score),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Circular progress
                    _CircularScore(score: score, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textSecondary.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: _textSecondary),
        ),
      ],
    );
  }
}

// --- Score bar ---

class _ScoreBar extends StatelessWidget {
  final int score;
  const _ScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ТОЧНОСТЬ ВАЛИДАЦИИ',
          style: TextStyle(
            fontSize: 11,
            color: _textSecondary,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_colorLow, _colorMedium, _colorHigh],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _Tick('0'),
            _Tick('2'),
            _Tick('4'),
            _Tick('6'),
            _Tick('8'),
            _Tick('10'),
          ],
        ),
      ],
    );
  }
}

class _Tick extends StatelessWidget {
  final String label;
  const _Tick(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        color: _textSecondary.withValues(alpha: 0.4),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// --- Circular score ---

class _CircularScore extends StatelessWidget {
  final int score;
  final Color color;
  const _CircularScore({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _CircularProgressPainter(
              progress: score / 100,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'score',
                style: TextStyle(
                  fontSize: 10,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 34.0;
    const strokeWidth = 6.0;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.05),
    );

    // Progress arc
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.color != color;
}

// --- Pulsing status dot ---

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Background painters (same as auth_page) ---

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
