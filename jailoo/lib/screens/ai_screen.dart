import 'dart:math';
import 'package:flutter/material.dart';
import '../data/zones.dart';
import '../services/ai_service.dart';
import '../theme/colors.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _messages = <_Message>[];
  bool _thinking = false;

  // Sparkle animation on the header icon
  late AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  final _controller = TextEditingController();
  final _aiService = AiService();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Best zone logic
  // ---------------------------------------------------------------------------

  Future<void> _send() async {
    if (_thinking) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _thinking = true;
      _messages.add(_Message(
        role: 'user',
        text: text,
      ));
    });
    _controller.clear();
    _scrollDown();

    final response = await _aiService.getRecommendation(text, kZones);

    setState(() {
      _messages.add(_Message(
        role: 'ai',
        text: response,
      ));
      _thinking = false;
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _buildHeader(c),
          Divider(height: 1, color: c.border),
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState(c) : _buildMessages(c),
          ),
          _buildInput(c),
        ],
      ),
    );
  }

  Widget _buildHeader(JailooColors c) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _sparkleCtrl,
              builder: (_, __) {
                final v = Curves.easeInOut.transform(_sparkleCtrl.value);
                return Transform.scale(
                  scale: 0.9 + v * 0.1,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.08 + v * 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.2 + v * 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: c.accent,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  'Pasture advisor · Naryn Oblast',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(JailooColors c) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                const Text(
                  '🌿',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  'Smart Pasture Advisor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ask a question below to find the best available zone for your herd right now.',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'What I can help with:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        ..._suggestions.map((s) => _SuggestionChip(text: s, c: c)),
      ],
    );
  }

  static const _suggestions = [
    '🐑  Find the nearest healthy zone',
    '📊  Check zone capacity for my herd',
    '🗺  Plan optimal grazing route',
    '⛰  Best alpine meadow this season',
  ];

  Widget _buildMessages(JailooColors c) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_thinking ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _ThinkingBubble(c: c);
        final msg = _messages[i];
        return _Bubble(isUser: msg.role == 'user', text: msg.text, c: c);
      },
    );
  }

  Widget _buildInput(JailooColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Спросите о пастбище...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                filled: true,
                fillColor: c.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: c.accent, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_upward, color: c.bg, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Message {
  final String role;
  final String text;
  const _Message({required this.role, required this.text});
}

// ---------------------------------------------------------------------------
// Chat bubbles
// ---------------------------------------------------------------------------

class _Bubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final JailooColors c;
  const _Bubble({required this.isUser, required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? c.accent : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
          border: isUser ? null : Border.all(color: c.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isUser ? Colors.white : c.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  final JailooColors c;
  const _ThinkingBubble({required this.c});

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
      duration: const Duration(milliseconds: 900),
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
    final c = widget.c;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(2),
          ),
          border: Border.all(color: c.border),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
                final opacity = 0.3 + sin(phase * pi) * 0.7;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.textMuted.withValues(alpha: opacity),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zone recommendation card (rich AI response)
// ---------------------------------------------------------------------------



// ---------------------------------------------------------------------------
// Suggestion chips (decorative, tap = coming soon toast)
// ---------------------------------------------------------------------------

class _SuggestionChip extends StatelessWidget {
  final String text;
  final JailooColors c;
  const _SuggestionChip({required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Manual prompts coming soon — use the button below'),
            backgroundColor: c.surface,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: c.textPrimary),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
