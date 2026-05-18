import 'dart:math';

import 'package:flutter/material.dart';

import '../services/room_service.dart';

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
  final _roomService = RoomService();
  bool _isCreating = false;
  String? _createError;
  bool _nameHasError = false;
  bool _descriptionHasError = false;
  bool _languageHasError = false;
  List<String> _languages = [];
  bool _isLoadingLanguages = true;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _addCriterion();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final languages = await _roomService.getLanguages();
      if (mounted) {
        setState(() {
          _languages = languages;
          _isLoadingLanguages = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLanguages = false);
    }
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
    FocusScope.of(context).unfocus();
    setState(() {
      _criteria[index].state = _CriterionState.validating;
    });

    try {
      final canAiVerify = await _roomService.verifyCriterion(
        _criteria[index].controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _criteria[index].state =
            canAiVerify ? _CriterionState.success : _CriterionState.warning;
        _criteria[index].message = canAiVerify
            ? 'Критерий может быть автоматически проверен ИИ'
            : 'Критерий слишком субъективен для автопроверки ИИ';
        _criteria[index].aiEnabled = canAiVerify;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _criteria[index].state = _CriterionState.initial;
        _criteria[index].hasError = true;
        _criteria[index].errorMessage = 'Ошибка проверки, попробуйте снова';
      });
    }
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
          decoration: _inputDecoration('Backend Development 2024', isError: _nameHasError, errorText: 'Введите название комнаты'),
          onChanged: (_) { if (_nameHasError) setState(() => _nameHasError = false); },
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
        if (_isLoadingLanguages)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x801F2937),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_accentPrimary),
                ),
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            dropdownColor: const Color(0xFF1F2937),
            style: const TextStyle(color: _textPrimary, fontSize: 15),
            decoration: _inputDecoration('Выберите язык', isError: _languageHasError, errorText: 'Выберите язык программирования'),
            items: _languages
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value;
                _languageHasError = false;
              });
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
            isError: _descriptionHasError,
            errorText: 'Введите описание задачи',
          ),
          onChanged: (_) { if (_descriptionHasError) setState(() => _descriptionHasError = false); },
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
          TextField(
            controller: criterion.controller,
            enabled: criterion.state == _CriterionState.initial,
            readOnly: criterion.state != _CriterionState.initial,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            onChanged: (_) {
              if (criterion.hasError) {
                setState(() {
                  criterion.hasError = false;
                  criterion.errorMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Например: Покрытие unit-тестами ≥ 80%',
              hintStyle: TextStyle(
                color: _textSecondary.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: criterion.hasError
                  ? _error.withValues(alpha: 0.05)
                  : const Color(0x801F2937),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: criterion.hasError
                    ? const BorderSide(color: _error, width: 1.5)
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: criterion.hasError
                    ? const BorderSide(color: _error, width: 1.5)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: criterion.hasError ? _error : _accentPrimary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              errorText: criterion.hasError ? criterion.errorMessage : null,
              errorStyle: const TextStyle(color: _error, fontSize: 12),
              suffix: criterion.state == _CriterionState.initial
                  ? GestureDetector(
                      onTap: () => _validateCriterion(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accentPrimary,
                          borderRadius: BorderRadius.circular(6),
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
                  : criterion.state == _CriterionState.validating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_accentPrimary),
                          ),
                        )
                      : null,
            ),
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

  Future<void> _createRoom() async {
    // Валидация
    final nameEmpty = _nameController.text.trim().isEmpty;
    final descEmpty = _descriptionController.text.trim().isEmpty;
    final langEmpty = _selectedLanguage == null;
    final criteriaErrors = _criteria.map((c) => c.controller.text.trim().isEmpty).toList();

    if (nameEmpty || descEmpty || langEmpty || criteriaErrors.contains(true)) {
      setState(() {
        _nameHasError = nameEmpty;
        _descriptionHasError = descEmpty;
        _languageHasError = langEmpty;
        for (int i = 0; i < _criteria.length; i++) {
          _criteria[i].hasError = criteriaErrors[i];
          if (criteriaErrors[i]) _criteria[i].errorMessage = 'Введите текст критерия';
        }
      });
      return;
    }

    // Показать подтверждение
    final confirmed = await _showConfirmSheet();
    if (confirmed != true) return;

    setState(() {
      _isCreating = true;
      _createError = null;
    });
    try {
      final criteriaList = _criteria
          .map((c) => {
                'criterion_text': c.controller.text.trim(),
                'is_ai_verified': c.aiEnabled,
              })
          .toList();
      await _roomService.createRoom(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        criteria: criteriaList,
        language: _selectedLanguage,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _createError = e.toString());
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<bool?> _showConfirmSheet() {
    final name = _nameController.text.trim();
    final desc = _descriptionController.text.trim();
    final lang = _selectedLanguage!;
    final aiCount = _criteria.where((c) => c.aiEnabled).length;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0x3300D4FF))),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accentPrimary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: _accentPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Подтвердите создание',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        'Проверьте данные перед созданием комнаты',
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow(Icons.meeting_room_outlined, 'Название', name),
                  const SizedBox(height: 12),
                  _summaryRow(Icons.code_outlined, 'Язык', lang),
                  const SizedBox(height: 12),
                  _summaryRow(
                    Icons.description_outlined,
                    'Описание',
                    desc.length > 80 ? '${desc.substring(0, 80)}…' : desc,
                  ),
                  const SizedBox(height: 12),
                  _summaryRow(
                    Icons.checklist_outlined,
                    'Критерии',
                    '${_criteria.length} · $aiCount с автопроверкой ИИ',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Отмена',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [_accentPrimary, _accentSecondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentPrimary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Создать комнату',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: _textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Column(
      children: [
        if (_createError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: _error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _createError!,
                    style: const TextStyle(color: _error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              onTap: _isCreating ? null : _createRoom,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
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
        ),
      ],
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

  InputDecoration _inputDecoration(String hint, {bool isError = false, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _textSecondary.withValues(alpha: 0.4),
      ),
      filled: true,
      fillColor: isError
          ? _error.withValues(alpha: 0.05)
          : const Color(0x801F2937),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: isError
            ? const BorderSide(color: _error, width: 1.5)
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: isError
            ? const BorderSide(color: _error, width: 1.5)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isError ? _error : _accentPrimary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      errorText: isError ? errorText : null,
      errorStyle: const TextStyle(color: _error, fontSize: 12),
    );
  }
}

enum _CriterionState { initial, validating, success, warning }

class _Criterion {
  final int number;
  final TextEditingController controller;
  _CriterionState state;
  String? message;
  bool aiEnabled = false;
  bool hasError = false;
  String? errorMessage;

  _Criterion({
    required this.number,
    required this.controller,
    required this.state,
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
