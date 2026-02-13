import 'dart:math';

import 'package:flutter/material.dart';

const _accentPrimary = Color(0xFF00D4FF);
const _accentSecondary = Color(0xFF7C3AED);
const _textPrimary = Color(0xFFF9FAFB);
const _textSecondary = Color(0xFF9CA3AF);
const _borderColor = Color(0x3300D4FF);
const _bgCard = Color(0x99111827);
const _success = Color(0xFF10B981);
const _error = Color(0xFFEF4444);
const _warning = Color(0xFFF59E0B);

class RoomPage extends StatefulWidget {
  final String roomName;
  final String company;

  const RoomPage({
    super.key,
    required this.roomName,
    this.company = 'HSE Inc',
  });

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late PageController _pageController;
  int _currentTab = 0;
  final _githubController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pageController = PageController();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController.dispose();
    _githubController.dispose();
    super.dispose();
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
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildTaskTab(),
                      _buildResultTab(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A).withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: _textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_outlined,
                          size: 14,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.company,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(child: _tab(0, 'Задание')),
                const SizedBox(width: 8),
                Expanded(child: _tab(1, 'Результат')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(int index, String label) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? _accentPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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

  Widget _buildTaskTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Task Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Описание задачи',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TypeScript',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'До 25 фев',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Разработать REST API для системы аутентификации с использованием JWT токенов. '
                'Необходимо реализовать endpoints для регистрации, входа, обновления токена и выхода. '
                'Все данные должны валидироваться согласно схемам. Обязательно покрытие тестами критических путей.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Criteria
              const Text(
                'Критерии',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              ..._buildCriteria(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Submit Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Отправить решение',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GitHub репозиторий',
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _githubController,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'https://github.com/username/repository',
                  hintStyle: TextStyle(
                    color: _textSecondary.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: const Color(0x801F2937),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _accentPrimary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      // TODO: Submit to API
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: const Text(
                        'Отправить на проверку',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
      ],
    );
  }

  List<Widget> _buildCriteria() {
    final criteria = [
      ('Покрытие unit-тестами ≥ 80%', true),
      ('Все endpoints возвращают правильные HTTP статусы', true),
      ('Валидация входных данных с использованием схем', false),
      ('Обработка ошибок и edge cases', true),
      ('Документация API (README + комментарии)', false),
      ('Соблюдение code style и линтер без ошибок', true),
    ];

    return criteria.map((criterion) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 20,
              color: _accentPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                criterion.$1,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _textPrimary,
                ),
              ),
            ),
            if (criterion.$2)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _accentSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _accentSecondary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 12,
                      color: _accentSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AUTO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _accentSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildResultTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Score cards
        Row(
          children: [
            Expanded(child: _scoreCard('Автопроверка', 85, 100, _success)),
            const SizedBox(width: 12),
            Expanded(child: _scoreCard('Ревью', 78, 100, _warning)),
          ],
        ),
        const SizedBox(height: 24),

        // Auto-check results
        const Text(
          'Автопроверка',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        _resultItem(
          title: 'Покрытие unit-тестами ≥ 80%',
          description:
              'Отличная работа! Покрытие составляет 87%, все критические функции протестированы. '
              'Обнаружено 45 тестов, все проходят успешно.',
          status: 'Выполнено: 87%',
          type: ResultType.success,
          badge: ResultBadge.auto,
        ),

        _resultItem(
          title: 'Правильные HTTP статусы',
          description:
              'Все endpoints корректно возвращают статусы. Проверено: 200 OK, 201 Created, 401 Unauthorized, '
              '422 Validation Error.',
          status: 'Выполнено',
          type: ResultType.success,
          badge: ResultBadge.auto,
        ),

        _resultItem(
          title: 'Обработка ошибок и edge cases',
          description:
              'Реализован middleware для обработки ошибок. Try-catch блоки присутствуют во всех асинхронных операциях. '
              'Ошибки логируются корректно.',
          status: 'Выполнено',
          type: ResultType.success,
          badge: ResultBadge.auto,
        ),

        _resultItem(
          title: 'Code style и линтер',
          description:
              'ESLint проверка пройдена успешно, 0 ошибок. Код соответствует Airbnb style guide. '
              'Форматирование единообразное, используется Prettier.',
          status: 'Выполнено',
          type: ResultType.success,
          badge: ResultBadge.auto,
        ),

        const SizedBox(height: 32),

        // Expert review
        const Text(
          'Ревью эксперта',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        _resultItem(
          title: 'Валидация входных данных',
          description:
              'Базовая валидация присутствует, но отсутствуют проверки для некоторых edge cases. '
              'Рекомендуется добавить валидацию email формата и длины пароля.',
          status: 'Частично: 65%',
          type: ResultType.warning,
          badge: ResultBadge.human,
        ),

        _resultItem(
          title: 'Документация API',
          description:
              'README файл содержит только базовую информацию. Отсутствует описание endpoints, примеры запросов '
              'и ответов. Необходимо добавить документацию для всех API методов.',
          status: 'Не выполнено: 30%',
          type: ResultType.failed,
          badge: ResultBadge.human,
        ),
      ],
    );
  }

  Widget _scoreCard(String label, int value, int max, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
              textBaseline: TextBaseline.alphabetic,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'из $max',
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultItem({
    required String title,
    required String description,
    required String status,
    required ResultType type,
    required ResultBadge badge,
  }) {
    Color iconColor;
    Color borderColor;
    Color statusBgColor;
    Color statusColor;
    IconData icon;

    switch (type) {
      case ResultType.success:
        iconColor = _success;
        borderColor = _success;
        statusBgColor = _success.withValues(alpha: 0.1);
        statusColor = _success;
        icon = Icons.check_circle;
      case ResultType.warning:
        iconColor = _warning;
        borderColor = _warning;
        statusBgColor = _warning.withValues(alpha: 0.1);
        statusColor = _warning;
        icon = Icons.warning;
      case ResultType.failed:
        iconColor = _error;
        borderColor = _error;
        statusBgColor = _error.withValues(alpha: 0.1);
        statusColor = _error;
        icon = Icons.cancel;
    }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badge == ResultBadge.auto
                                ? _accentSecondary.withValues(alpha: 0.15)
                                : _accentPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: badge == ResultBadge.auto
                                  ? _accentSecondary.withValues(alpha: 0.4)
                                  : _accentPrimary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badge == ResultBadge.auto
                                    ? Icons.psychology_outlined
                                    : Icons.person_outline,
                                size: 11,
                                color: badge == ResultBadge.auto
                                    ? _accentSecondary
                                    : _accentPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badge == ResultBadge.auto ? 'AUTO' : 'РЕВЬЮ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: badge == ResultBadge.auto
                                      ? _accentSecondary
                                      : _accentPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 12, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
          ),
        ),
        // Colored left border
        Positioned(
          left: 0,
          top: 0,
          bottom: 16,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum ResultType { success, warning, failed }

enum ResultBadge { auto, human }

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
