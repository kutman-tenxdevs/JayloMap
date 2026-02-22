import 'dart:math';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../data/zones.dart';
import '../theme/colors.dart';

// ---------------------------------------------------------------------------
// Message model
// ---------------------------------------------------------------------------

enum _Role { user, ai }

class _Msg {
  final _Role role;
  final String text;
  const _Msg({required this.role, required this.text});
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _aiService = AiService();
  final List<_Msg> _messages = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_Msg(role: _Role.user, text: text));
      _loading = true;
    });
    _controller.clear();
    _scrollDown();

    final response = await _aiService.getRecommendation(text, kZones);

    setState(() {
      _messages.add(_Msg(role: _Role.ai, text: response));
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: c.accent),
            const SizedBox(width: 8),
            Text(
              'AI Помощник',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1, color: c.border),
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState(c) : _buildMessages(c),
          ),
          _buildInput(c),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state with preset chips
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(JailooColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.landscape_outlined, color: c.accent, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'Спросите о пастбищах',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Получите рекомендации для вашего стада\nна основе актуальных данных зон',
            style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Популярные вопросы',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map((p) => _PresetChip(
                      label: p.label,
                      colors: c,
                      onTap: () => _sendText(p.query),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message list
  // ---------------------------------------------------------------------------

  Widget _buildMessages(JailooColors c) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _ThinkingBubble(colors: c);

        final msg = _messages[index];
        if (msg.role == _Role.user) {
          return _UserBubble(text: msg.text, colors: c);
        }
        return _AiBubble(text: msg.text, colors: c);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Input bar
  // ---------------------------------------------------------------------------

  Widget _buildInput(JailooColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Спросите о пастбищах...',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: _loading ? null : _send,
              style: IconButton.styleFrom(
                backgroundColor: _loading ? c.surface2 : c.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                Icons.arrow_upward,
                color: _loading ? c.textMuted : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User bubble
// ---------------------------------------------------------------------------

class _UserBubble extends StatelessWidget {
  final String text;
  final JailooColors colors;
  const _UserBubble({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI text bubble
// ---------------------------------------------------------------------------

class _AiBubble extends StatelessWidget {
  final String text;
  final JailooColors colors;
  const _AiBubble({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: colors.textPrimary,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thinking animation — 3 bouncing dots
// ---------------------------------------------------------------------------

class _ThinkingBubble extends StatefulWidget {
  final JailooColors colors;
  const _ThinkingBubble({required this.colors});

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: widget.colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Думаю',
              style: TextStyle(
                fontSize: 12,
                color: widget.colors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(3, (i) => _Dot(ctrl: _ctrl, index: i, colors: widget.colors)),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController ctrl;
  final int index;
  final JailooColors colors;
  const _Dot({required this.ctrl, required this.index, required this.colors});

  @override
  Widget build(BuildContext context) {
    // Each dot is offset by 0.33 in the [0,1] animation cycle
    final offset = index * 0.25;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ((ctrl.value - offset) % 1.0);
        // Sine wave: peak at t=0.5, trough at 0 and 1
        final scale = 0.6 + 0.4 * sin(t * pi).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: scale),
            shape: BoxShape.circle,
          ),
          transform: Matrix4.identity()
            ..translate(0.0, -4.0 * sin(t * pi).clamp(0.0, 1.0)),
        );
      },
    );
  }
}


