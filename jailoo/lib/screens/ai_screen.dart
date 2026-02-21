import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../data/zones.dart';
import '../theme/colors.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _aiService = AiService();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });
    _controller.clear();
    _scrollDown();

    final response = await _aiService.getRecommendation(text, kZones);

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
              'AI Assistant',
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
            child: _messages.isEmpty
                ? _buildEmptyState(c)
                : _buildMessages(c),
          ),
          _buildInput(c),
        ],
      ),
    );
  }

  Widget _buildEmptyState(JailooColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Icon(
                Icons.landscape_outlined,
                color: c.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask about pastures',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'e.g. "I have 60 sheep, where should I go?"',
              style: TextStyle(fontSize: 13, color: c.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(JailooColors c) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _LoadingBubble(colors: c);
        final msg = _messages[index];
        return _Bubble(
          role: msg['role']!,
          text: msg['text']!,
          colors: c,
        );
      },
    );
  }

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
                  hintText: 'Ask a question...',
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
              onPressed: _send,
              style: IconButton.styleFrom(
                backgroundColor: c.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String role;
  final String text;
  final JailooColors colors;
  const _Bubble({
    required this.role,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: isUser ? null : Border.all(color: colors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isUser ? Colors.white : colors.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  final JailooColors colors;
  const _LoadingBubble({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: SizedBox(
          width: 24,
          height: 16,
          child: Center(
            child: Text(
              '...',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
