import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/room_detail.dart';
import '../services/room_service.dart';

const _accentPrimary = Color(0xFF00D4FF);
const _accentSecondary = Color(0xFF7C3AED);
const _textPrimary = Color(0xFFF9FAFB);
const _textSecondary = Color(0xFF9CA3AF);
const _borderColor = Color(0x3300D4FF);
const _success = Color(0xFF10B981);
const _error = Color(0xFFEF4444);
const _warning = Color(0xFFF59E0B);

enum _RoomStatus { notStarted, active, archive }

class ManageRoomPage extends StatefulWidget {
  final String roomId;

  const ManageRoomPage({super.key, required this.roomId});

  @override
  State<ManageRoomPage> createState() => _ManageRoomPageState();
}

class _ManageRoomPageState extends State<ManageRoomPage>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late PageController _pageController;
  int _currentTab = 0;

  final _roomService = RoomService();
  RoomDetail? _roomDetail;
  bool _isLoadingDetail = true;
  String? _loadError;

  // Participants
  List<Map<String, dynamic>>? _members;
  bool _isLoadingMembers = true;
  String? _membersError;

  // Settings form state
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  _RoomStatus _selectedStatus = _RoomStatus.active;
  double _aiWeight = 40;
  DateTime? _deadline;
  bool _isSaving = false;
  String? _saveError;
  String? _saveSuccess;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _pageController = PageController();
    _loadRoomDetail();
    _loadParticipants();
  }

  Future<void> _loadRoomDetail() async {
    try {
      final detail = await _roomService.getRoom(widget.roomId);
      if (mounted) {
        setState(() {
          _roomDetail = detail;
          _nameController.text = detail.name;
          _passwordController.text = detail.password ?? '';
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoadingDetail = false;
        });
      }
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final members = await _roomService.getRoomMembers(widget.roomId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _membersError = e.toString();
          _isLoadingMembers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
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

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
      _saveSuccess = null;
    });
    // TODO: call update room API
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _isSaving = false;
        _saveSuccess = 'Настройки сохранены';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) => CustomPaint(
                painter: _BackgroundPainter(_bgController.value * 2 * pi),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildSettingsTab(),
                      _buildParticipantsTab(),
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
                      _roomDetail?.name ?? 'Управление комнатой',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'ID: ${widget.roomId}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _tab(0, 'Настройки')),
              const SizedBox(width: 8),
              Expanded(child: _tab(1, 'Участники')),
            ],
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
                  gradient: const LinearGradient(
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

  // ── Settings Tab ──────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    if (_isLoadingDetail) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentPrimary),
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
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
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _label('Статус комнаты'),
        const SizedBox(height: 8),
        _buildStatusToggle(),
        const SizedBox(height: 20),

        _label('Название комнаты'),
        const SizedBox(height: 8),
        _buildTextField(_nameController, 'Название комнаты'),
        const SizedBox(height: 20),

        _label('ID комнаты'),
        const SizedBox(height: 8),
        _buildCopyableField(widget.roomId, monospace: true),
        const SizedBox(height: 20),

        _label('Пароль для входа'),
        const SizedBox(height: 8),
        _buildPasswordField(),
        const SizedBox(height: 20),

        _label('Дедлайн'),
        const SizedBox(height: 8),
        _buildDeadlinePicker(),
        const SizedBox(height: 20),

        _label('Вес балла ИИ в итоговом балле'),
        const SizedBox(height: 8),
        _buildWeightSlider(),
        const SizedBox(height: 32),

        if (_saveError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: _error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _saveError!,
                    style: const TextStyle(color: _error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_saveSuccess != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: _success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _saveSuccess!,
                    style: const TextStyle(color: _success, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        _buildSaveButton(),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Row(
      children: [
        Expanded(
          child: _statusOption(
            _RoomStatus.notStarted,
            Icons.info_outline,
            'Не начата',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statusOption(
            _RoomStatus.active,
            Icons.check_circle_outline,
            'Активна',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statusOption(
            _RoomStatus.archive,
            Icons.archive_outlined,
            'Архив',
          ),
        ),
      ],
    );
  }

  Widget _statusOption(_RoomStatus status, IconData icon, String label) {
    final isSelected = _selectedStatus == status;

    Color borderColor;
    Color textColor;
    Color bgColor;

    switch (status) {
      case _RoomStatus.notStarted:
        borderColor = isSelected ? _warning : Colors.transparent;
        textColor = isSelected ? _warning : _textSecondary;
        bgColor = isSelected
            ? _warning.withValues(alpha: 0.1)
            : const Color(0x801F2937);
      case _RoomStatus.active:
        borderColor = isSelected ? _success : Colors.transparent;
        textColor = isSelected ? _success : _textSecondary;
        bgColor = isSelected
            ? _success.withValues(alpha: 0.1)
            : const Color(0x801F2937);
      case _RoomStatus.archive:
        borderColor = isSelected ? _textSecondary : Colors.transparent;
        textColor =
            isSelected ? _textSecondary : _textSecondary.withValues(alpha: 0.6);
        bgColor = isSelected
            ? _textSecondary.withValues(alpha: 0.1)
            : const Color(0x801F2937);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: _textSecondary.withValues(alpha: 0.4)),
        filled: true,
        fillColor: const Color(0x801F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCopyableField(String value, {bool monospace = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x401F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _textPrimary.withValues(alpha: 0.6),
                fontSize: 15,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CopyButton(value: value),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x801F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Введите пароль',
                hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.4)),
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _passwordVisible = !_passwordVisible),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: _textSecondary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _CopyButton(value: _passwordController.text),
        ],
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _deadline ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _accentPrimary,
                onPrimary: Colors.black,
                surface: Color(0xFF1F2937),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _deadline = picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x801F2937),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _deadline != null
                    ? '${_deadline!.day.toString().padLeft(2, '0')}.${_deadline!.month.toString().padLeft(2, '0')}.${_deadline!.year}'
                    : 'Выберите дату',
                style: TextStyle(
                  color: _deadline != null
                      ? _textPrimary
                      : _textSecondary.withValues(alpha: 0.4),
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: _textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSlider() {
    final reviewWeight = 100 - _aiWeight.round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x4D1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _accentPrimary,
                    inactiveTrackColor:
                        _accentSecondary.withValues(alpha: 0.3),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _aiWeight,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) => setState(() => _aiWeight = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x801F2937),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentPrimary, width: 1.5),
                ),
                child: Text(
                  '${_aiWeight.round()}%',
                  style: const TextStyle(
                    color: _accentPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _weightLabel('ИИ', '${_aiWeight.round()}%'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _weightLabel('Ревью', '$reviewWeight%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightLabel(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _accentPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
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
          onTap: _isSaving ? null : _saveSettings,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Сохранить изменения',
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

  // ── Participants Tab ──────────────────────────────────────────────────────

  Widget _buildParticipantsTab() {
    if (_isLoadingMembers) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentPrimary),
        ),
      );
    }

    if (_membersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _error.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _error, size: 28),
                const SizedBox(height: 12),
                Text(
                  _membersError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    setState(() { _isLoadingMembers = true; _membersError = null; });
                    _loadParticipants();
                  },
                  child: const Text('Повторить', style: TextStyle(color: _accentPrimary, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final members = _members ?? [];

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, color: _textSecondary.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Участников пока нет',
              style: TextStyle(color: _textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final criteria = _roomDetail?.criteria ?? [];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: members.length,
      itemBuilder: (_, i) => _ParticipantCard(
        member: members[i],
        criteria: criteria,
        roomId: widget.roomId,
        roomService: _roomService,
        onScoreSubmitted: _loadParticipants,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: _textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Participant Card ──────────────────────────────────────────────────────

class _ParticipantCard extends StatefulWidget {
  final Map<String, dynamic> member;
  final List<RoomCriterion> criteria;
  final String roomId;
  final RoomService roomService;
  final VoidCallback onScoreSubmitted;

  const _ParticipantCard({
    required this.member,
    required this.criteria,
    required this.roomId,
    required this.roomService,
    required this.onScoreSubmitted,
  });

  @override
  State<_ParticipantCard> createState() => _ParticipantCardState();
}

class _ParticipantCardState extends State<_ParticipantCard> {
  late final List<TextEditingController> _scoreControllers;
  late final TextEditingController _generalCommentController;
  bool _isSubmitting = false;
  String? _submitError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final ownerScore = _ownerScore;
    // Распределяем существующий owner_score равномерно по критериям (0-10 шкала)
    final perCriterionInit = (ownerScore != null && widget.criteria.isNotEmpty)
        ? (ownerScore / 10).toStringAsFixed(1)
        : '';
    _scoreControllers = List.generate(
      widget.criteria.length,
      (_) => TextEditingController(text: perCriterionInit),
    );
    _generalCommentController = TextEditingController(text: _ownerComment ?? '');
    _submitted = ownerScore != null;
  }

  @override
  void dispose() {
    for (final c in _scoreControllers) {
      c.dispose();
    }
    _generalCommentController.dispose();
    super.dispose();
  }

  int get _userId => (widget.member['user_id'] as num).toInt();
  String get _username => widget.member['username'] as String? ?? 'Участник #$_userId';
  String get _email => widget.member['email'] as String? ?? '';
  double? get _aiScore => (widget.member['ai_score'] as num?)?.toDouble();
  double? get _ownerScore => (widget.member['owner_score'] as num?)?.toDouble();
  double? get _finalScore => (widget.member['final_score'] as num?)?.toDouble();
  int get _submissionsCount => (widget.member['submissions_count'] as num?)?.toInt() ?? 0;
  String? get _submissionUrl => widget.member['submission_url'] as String?;
  String? get _ownerComment => widget.member['owner_comment'] as String?;

  double? _calcReviewScore() {
    final vals = _scoreControllers
        .map((c) => double.tryParse(c.text))
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Future<void> _submit() async {
    final reviewScore = _calcReviewScore();
    if (reviewScore == null) {
      setState(() => _submitError = 'Выставьте баллы по всем критериям');
      return;
    }

    setState(() { _isSubmitting = true; _submitError = null; });
    try {
      final comment = _generalCommentController.text.trim();
      await widget.roomService.setOwnerScore(
        widget.roomId,
        _userId,
        reviewScore * 10,
        comment: comment.isEmpty ? null : comment,
      );
      if (mounted) {
        setState(() { _isSubmitting = false; _submitted = true; });
        widget.onScoreSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isSubmitting = false; _submitError = e.toString().replaceFirst('Exception: ', ''); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x99111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_submissionUrl != null) ...[
            _buildGithubLink(_submissionUrl!),
            const SizedBox(height: 20),
          ] else if (_submissionsCount == 0) ...[
            _buildNoSubmission(),
            const SizedBox(height: 20),
          ],
          if (widget.criteria.isNotEmpty && _submissionsCount > 0) ...[
            _buildCriteriaScoring(),
            const SizedBox(height: 4),
            _buildScoresSummary(),
            const SizedBox(height: 16),
            _buildGeneralComment(),
            const SizedBox(height: 16),
            if (_submitError != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: _error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_submitError!, style: const TextStyle(color: _error, fontSize: 13))),
                  ],
                ),
              ),
            ],
            _buildSubmitButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isGraded = _ownerScore != null;
    final autoScore = _aiScore;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGraded
                          ? _success.withValues(alpha: 0.15)
                          : _warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isGraded
                            ? _success.withValues(alpha: 0.3)
                            : _warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isGraded ? 'ОЦЕНЕНА' : 'НА ПРОВЕРКЕ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isGraded ? _success : _warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Отправки: $_submissionsCount',
                      style: const TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (autoScore != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _accentSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentSecondary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'AUTO',
                  style: TextStyle(
                    fontSize: 10,
                    color: _textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  autoScore.round().toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _accentSecondary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGithubLink(String url) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.code, size: 18, color: _accentPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(fontSize: 13, color: _accentPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _CopyButton(value: url),
        ],
      ),
    );
  }

  Widget _buildNoSubmission() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Row(
        children: [
          Icon(Icons.inbox_outlined, size: 18, color: _textSecondary),
          SizedBox(width: 8),
          Text(
            'Решение ещё не отправлено',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaScoring() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Оценка по критериям',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(widget.criteria.length, (i) {
          final criterion = widget.criteria[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    criterion.criterionText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _scoreControllers[i],
                    readOnly: _submitted,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _submitted
                          ? const Color(0x261F2937)
                          : const Color(0x801F2937),
                      hintText: '—',
                      hintStyle: TextStyle(
                          color: _textSecondary.withValues(alpha: 0.4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: _accentPrimary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '/ 10',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScoresSummary() {
    final reviewScore = _submitted ? (_ownerScore != null ? _ownerScore! / 10 : null) : _calcReviewScore();
    final autoVal = _aiScore != null ? _aiScore! / 10 : null;
    final finalScore = _finalScore != null
        ? _finalScore! / 10
        : (autoVal != null && reviewScore != null
            ? autoVal * 0.4 + reviewScore * 0.6
            : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _accentPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _accentPrimary.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        children: [
          if (autoVal != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _scoreRow(
                icon: SvgPicture.asset('assets/icons/ai_chip.svg',
                    width: 12,
                    height: 12,
                    colorFilter:
                        ColorFilter.mode(_accentSecondary, BlendMode.srcIn)),
                label: 'ИИ балл',
                detail: 'Автопроверка',
                value: autoVal.toStringAsFixed(1),
                valueColor: _accentSecondary,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, autoVal != null ? 0 : 16, 16, 0),
            child: _scoreRow(
              icon: const Icon(Icons.person_outline,
                  size: 12, color: _accentPrimary),
              label: 'РЕВЬЮ балл',
              detail: '${widget.criteria.length} критериев',
              value: reviewScore != null
                  ? reviewScore.toStringAsFixed(1)
                  : '—',
              valueColor: _accentPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
              border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Итоговый балл',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '40% ИИ + 60% РЕВЬЮ',
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  finalScore != null
                      ? finalScore.toStringAsFixed(1)
                      : '—',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _success,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow({
    required Widget icon,
    required String label,
    required String detail,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 11, color: _textSecondary)),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralComment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Общий комментарий',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _generalCommentController,
          readOnly: _submitted,
          maxLines: 3,
          minLines: 3,
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            hintText: 'Оставьте общий комментарий для участника...',
            hintStyle:
                TextStyle(color: _textSecondary.withValues(alpha: 0.4)),
            filled: true,
            fillColor: _submitted
                ? const Color(0x261F2937)
                : const Color(0x801F2937),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _accentPrimary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: _submitted
            ? null
            : const LinearGradient(
                colors: [_success, Color(0xFF059669)],
              ),
        color: _submitted ? _success.withValues(alpha: 0.3) : null,
        boxShadow: _submitted
            ? []
            : [
                BoxShadow(
                  color: _success.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: (_submitted || _isSubmitting) ? null : _submit,
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
                : Text(
                    _submitted ? 'Баллы выставлены' : 'Выставить баллы',
                    style: TextStyle(
                      color: _submitted
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String value;
  const _CopyButton({required this.value});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _copied
              ? const Icon(Icons.check, size: 18, color: _success, key: ValueKey('check'))
              : const Icon(Icons.copy_outlined, size: 18, color: _textSecondary, key: ValueKey('copy')),
        ),
      ),
    );
  }
}

// Background painters (same style as other pages)
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
