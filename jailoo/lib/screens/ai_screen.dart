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
    return Scaffold(
      backgroundColor: JailooColors.bg,
      appBar: AppBar(
        backgroundColor: JailooColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: JailooColors.accent),
            SizedBox(width: 8),
            Text(
              'AI Assistant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: JailooColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: JailooColors.border),
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessages(),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                color: JailooColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JailooColors.border),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                color: JailooColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask about pastures',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: JailooColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'e.g. "I have 60 sheep, where should I go?"',
              style: TextStyle(
                fontSize: 13,
                color: JailooColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return const _LoadingBubble();
        final msg = _messages[index];
        return _Bubble(role: msg['role']!, text: msg['text']!);
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: JailooColors.bg,
        border: Border(top: BorderSide(color: JailooColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: JailooColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: JailooColors.border),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: JailooColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: TextStyle(color: JailooColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                backgroundColor: JailooColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.arrow_upward, color: JailooColors.bg, size: 18),
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
  const _Bubble({required this.role, required this.text});

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
          color: isUser ? JailooColors.accent : JailooColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: isUser ? null : Border.all(color: JailooColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isUser ? JailooColors.bg : JailooColors.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: JailooColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: JailooColors.border),
        ),
        child: const SizedBox(
          width: 24,
          height: 16,
          child: Center(
            child: Text(
              '...',
              style: TextStyle(
                color: JailooColors.textMuted,
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
