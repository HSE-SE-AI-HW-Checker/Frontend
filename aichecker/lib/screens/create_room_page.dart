import 'dart:math';

import 'package:flutter/material.dart';

const _accentPrimary = Color(0xFF00D4FF);
const _accentSecondary = Color(0xFF7C3AED);
const _textPrimary = Color(0xFFF9FAFB);
const _textSecondary = Color(0xFF9CA3AF);
const _borderColor = Color(0x3300D4FF);
const _bgCard = Color(0x99111827);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _error = Color(0xFFEF4444);

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedLanguage;
  final List<_Criterion> _criteria = [];
  int _criterionCounter = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Add initial criterion
    _addCriterion();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    for (var criterion in _criteria) {
      criterion.controller.dispose();
    }
    super.dispose();
  }

  void _addCriterion() {
    setState(() {
      _criterionCounter++;
      _criteria.add(_Criterion(
        number: _criterionCounter,
        controller: TextEditingController(),
        state: _CriterionState.initial,
      ));
    });
  }

  void _deleteCriterion(int index) {
    setState(() {
      _criteria[index].controller.dispose();
      _criteria.removeAt(index);
    });
  }

  Future<void> _validateCriterion(int index) async {
    if (_criteria[index].controller.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _criteria[index].state = _CriterionState.validating;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Random result: 70% success, 30% warning
    final isSuccess = Random().nextDouble() > 0.3;

    setState(() {
      _criteria[index].state =
          isSuccess ? _CriterionState.success : _CriterionState.warning;
      _criteria[index].message = isSuccess
          ? 'Критерий может быть автоматически проверен ИИ'
          : 'Критерий слишком субъективен для автопроверки ИИ';
      _criteria[index].aiEnabled = isSuccess;
    });
  }

  void _toggleAI(int index) {
    if (_criteria[index].state != _CriterionState.success) return;

    setState(() {
      _criteria[index].aiEnabled = !_criteria[index].aiEnabled;
    });
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
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 32),
                      _buildCriteriaSection(),
                      const SizedBox(height: 32),
                      _buildCreateButton(),
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
      child: Row(
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
          const Text(
            'Создание комнаты',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Основная информация'),
        const SizedBox(height: 16),

        // Room Name
        const Text(
          'Название комнаты',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: _inputDecoration('Backend Development 2024'),
        ),
        const SizedBox(height: 20),

        // Programming Language
        const Text(
          'Язык программирования',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          dropdownColor: const Color(0xFF1F2937),
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: _inputDecoration('Выберите язык'),
          items: const [
            DropdownMenuItem(value: 'typescript', child: Text('TypeScript')),
            DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
            DropdownMenuItem(value: 'python', child: Text('Python')),
            DropdownMenuItem(value: 'java', child: Text('Java')),
            DropdownMenuItem(value: 'csharp', child: Text('C#')),
            DropdownMenuItem(value: 'go', child: Text('Go')),
            DropdownMenuItem(value: 'rust', child: Text('Rust')),
            DropdownMenuItem(value: 'php', child: Text('PHP')),
          ],
          onChanged: (value) {
            setState(() => _selectedLanguage = value);
          },
        ),
        const SizedBox(height: 20),

        // Description
        const Text(
          'Описание задачи',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration: _inputDecoration(
            'Опишите задачу, которую должны выполнить участники...',
          ),
        ),
      ],
    );
  }

  Widget _buildCriteriaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Критерии оценки'),
        const SizedBox(height: 16),

        // Criteria List - Reorderable
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _criteria.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final criterion = _criteria.removeAt(oldIndex);
              _criteria.insert(newIndex, criterion);
            });
          },
          itemBuilder: (context, index) {
            final criterion = _criteria[index];
            return _buildCriterionItem(index, criterion, key: ValueKey(criterion));
          },
        ),

        const SizedBox(height: 16),

        // Add Criterion Button
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _borderColor,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _addCriterion,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Добавить критерий',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCriterionItem(int index, _Criterion criterion, {Key? key}) {
    Color? borderColor;
    BoxShadow? shadow;

    switch (criterion.state) {
      case _CriterionState.validating:
        borderColor = _accentPrimary;
        shadow = BoxShadow(
          color: _accentPrimary.withValues(alpha: 0.1),
          blurRadius: 12,
          spreadRadius: 4,
        );
      case _CriterionState.success:
        borderColor = _success;
        shadow = BoxShadow(
          color: _success.withValues(alpha: 0.1),
          blurRadius: 12,
          spreadRadius: 4,
        );
      case _CriterionState.warning:
        borderColor = _warning;
        shadow = BoxShadow(
          color: _warning.withValues(alpha: 0.1),
          blurRadius: 12,
          spreadRadius: 4,
        );
      default:
        borderColor = _borderColor;
    }

    return ReorderableDragStartListener(
      index: index,
      key: key,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: shadow != null ? [shadow] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Критерий ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_criteria.length > 1)
                  GestureDetector(
                    onTap: () => _deleteCriterion(index),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _error.withValues(alpha: 0.1),
                        border: Border.all(
                          color: _error.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: _error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

          // Input with validation button
          Stack(
            children: [
              TextField(
                controller: criterion.controller,
                enabled: criterion.state == _CriterionState.initial,
                readOnly: criterion.state != _CriterionState.initial,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Например: Покрытие unit-тестами ≥ 80%',
                  hintStyle: TextStyle(
                    color: _textSecondary.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: const Color(0x801F2937),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _accentPrimary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 16,
                    right: 100,
                    top: 12,
                    bottom: 12,
                  ),
                ),
              ),

              // Validate button or loading spinner
              if (criterion.state == _CriterionState.initial)
                Positioned(
                  right: 8,
                  top: 8,
                  child: ElevatedButton(
                    onPressed: () => _validateCriterion(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        _accentPrimary,
                      ),
                    ),
                    child: const Text(
                      'Проверить',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (criterion.state == _CriterionState.validating)
                Positioned(
                  right: 16,
                  top: 16,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _accentPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Validation message
          if (criterion.message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: criterion.state == _CriterionState.success
                    ? _success.withValues(alpha: 0.1)
                    : _warning.withValues(alpha: 0.1),
                border: Border.all(
                  color: criterion.state == _CriterionState.success
                      ? _success.withValues(alpha: 0.3)
                      : _warning.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    criterion.state == _CriterionState.success
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                    size: 16,
                    color: criterion.state == _CriterionState.success
                        ? _success
                        : _warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      criterion.message!,
                      style: TextStyle(
                        fontSize: 12,
                        color: criterion.state == _CriterionState.success
                            ? _success
                            : _warning,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // AI Toggle - только для success состояния
          if (criterion.state == _CriterionState.success) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 14,
                        color: _accentSecondary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Автопроверка ИИ',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _toggleAI(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: criterion.aiEnabled
                            ? _accentPrimary
                            : _textSecondary.withValues(alpha: 0.2),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        alignment: criterion.aiEnabled
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
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
          onTap: () {
            // TODO: Create room
            Navigator.of(context).pop();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const Text(
              'Создать комнату',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentPrimary, _accentSecondary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}

enum _CriterionState { initial, validating, success, warning }

class _Criterion {
  final int number;
  final TextEditingController controller;
  _CriterionState state;
  String? message;
  bool aiEnabled;

  _Criterion({
    required this.number,
    required this.controller,
    required this.state,
    this.message,
    this.aiEnabled = false,
  });
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
