import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/room_detail.dart';
import '../services/room_service.dart';

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
  final String roomId;

  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late PageController _pageController;
  int _currentTab = 0;
  final _githubController = TextEditingController();
  final _roomService = RoomService();
  bool _isSubmitting = false;
  String? _submissionError;
  String? _submissionSuccess;

  RoomDetail? _roomDetail;
  bool _isLoadingDetail = true;
  String? _loadError;
  String? _deadline;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pageController = PageController();
    _githubController.addListener(_clearSubmissionMessages);
    _loadRoomDetail();
  }

  Future<void> _loadRoomDetail() async {
    try {
      final detail = await _roomService.getRoom(widget.roomId);
      if (mounted) setState(() { _roomDetail = detail; _isLoadingDetail = false; });
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _isLoadingDetail = false; });
    }
    try {
      final memberInfo = await _roomService.getRoomMemberInfo(widget.roomId);
      final rawDeadline = memberInfo['deadline'] as String?;
      if (rawDeadline != null && mounted) {
        setState(() { _deadline = _formatDeadline(rawDeadline); });
      }
    } catch (_) {}
  }

  String _formatDeadline(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return iso;
    }
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

  void _clearSubmissionMessages() {
    if (_submissionError != null || _submissionSuccess != null) {
      setState(() {
        _submissionError = null;
        _submissionSuccess = null;
      });
    }
  }

  Future<void> _submitSolution() async {
    final url = _githubController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _submissionError = 'Введите URL репозитория';
        _submissionSuccess = null;
      });
      return;
    }

    // Простая валидация URL
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _submissionError = 'URL должен начинаться с http:// или https://';
        _submissionSuccess = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
      _submissionSuccess = null;
    });

    try {
      final result = await _roomService.submitSolution(url);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _submissionSuccess = result['message'] ?? 'Решение успешно отправлено';
          _submissionError = null;
          _githubController.clear();
        });
      } else {
        setState(() {
          _submissionError = result['message'] ?? 'Ошибка отправки решения';
          _submissionSuccess = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                      _roomDetail?.name ?? widget.roomId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (_deadline != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: _textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Дедлайн: $_deadline',
                            style: const TextStyle(fontSize: 13, color: _textSecondary),
                          ),
                        ],
                      ),
                    ],
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

  Widget _sectionTitle(String text, Color stripeColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: stripeColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_isLoadingDetail)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentPrimary),
              ),
            ),
          )
        else if (_loadError != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: _error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _loadError!,
                    style: const TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else if (_roomDetail != null)
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _sectionTitle('Описание задачи', _accentPrimary)),
                    if (_roomDetail!.language != null && _roomDetail!.language!.isNotEmpty)
                      Text(
                        _roomDetail!.language!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          color: Color(0x809CA3AF),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _roomDetail!.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: _textSecondary,
                  ),
                ),
                if (_roomDetail!.criteria.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Критерии', _accentPrimary),
                  const SizedBox(height: 12),
                  ..._roomDetail!.criteria.map(_buildCriterionItem),
                ],
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
              _sectionTitle('Отправить решение', _accentSecondary),
              const SizedBox(height: 16),
              const Text(
                'Ссылка на репозиторий',
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

              // Error/Success messages
              if (_submissionError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: _error,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _submissionError!,
                          style: const TextStyle(
                            color: _error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_submissionSuccess != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _success.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: _success,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _submissionSuccess!,
                          style: const TextStyle(
                            color: _success,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                    onTap: _isSubmitting ? null : _submitSolution,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
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

  Widget _buildCriterionItem(RoomCriterion criterion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check, size: 20, color: _accentPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              criterion.criterionText,
              style: const TextStyle(fontSize: 14, height: 1.5, color: _textPrimary),
            ),
          ),
          if (criterion.isAiVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accentSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _accentSecondary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ai_chip.svg',
                    width: 12,
                    height: 12,
                    colorFilter: ColorFilter.mode(_accentSecondary, BlendMode.srcIn),
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
                              if (badge == ResultBadge.auto)
                                SvgPicture.asset(
                                  'assets/icons/ai_chip.svg',
                                  width: 11,
                                  height: 11,
                                  colorFilter: ColorFilter.mode(_accentSecondary, BlendMode.srcIn),
                                )
                              else
                                const Icon(
                                  Icons.person_outline,
                                  size: 11,
                                  color: _accentPrimary,
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
