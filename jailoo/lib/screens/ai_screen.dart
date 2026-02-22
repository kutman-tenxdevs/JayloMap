import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/app_controller.dart';
import '../data/zones.dart';
import '../models/zone.dart';
import '../theme/colors.dart';
import '../widgets/health_bar.dart';

// ---------------------------------------------------------------------------
// Message model
// ---------------------------------------------------------------------------

enum _Role { user, ai, zoneCard }

class _Msg {
  final _Role role;
  final String text;
  final Zone? zone;
  const _Msg({required this.role, this.text = '', this.zone});
}

// ---------------------------------------------------------------------------
// Preset suggestion chips
// ---------------------------------------------------------------------------

const _presets = [
  (label: '🌿 Лучшее пастбище', query: 'Какое пастбище сейчас лучшее для выпаса?'),
  (label: '🐑 Стадо 80 овец', query: 'У меня 80 овец, куда мне лучше идти?'),
  (label: '❓ Закрытые зоны', query: 'Какие зоны сейчас закрыты и почему?'),
  (label: '📅 Сары-Булак', query: 'На сколько дней хватит пастбище Сары-Булак?'),
  (label: '🗺 Сравни ближайшие', query: 'Сравни ближайшие зелёные пастбища между собой'),
  (label: '⚠️ Опасные зоны', query: 'Где сейчас опасно пасти скот и почему?'),
];

// Detect "best pasture" type queries — we'll attach a zone card to these.
bool _wantsRecommendation(String q) {
  final lower = q.toLowerCase();
  return lower.contains('лучш') ||
      lower.contains('куда') ||
      lower.contains('иди') ||
      lower.contains('рекомендуй') ||
      lower.contains('пастбищ') ||
      lower.contains('советуй') ||
      lower.contains('ближайш') ||
      lower.contains('сравни');
}

// Pick a random healthy (or recovering) zone for the card.
Zone _pickRecommendedZone() {
  final rng = Random();
  final healthy = kZones.where((z) => z.status == 'healthy').toList();
  if (healthy.isNotEmpty) return healthy[rng.nextInt(healthy.length)];
  final recovering = kZones.where((z) => z.status == 'recovering').toList();
  return recovering[rng.nextInt(recovering.length)];
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

  Future<void> _sendText(String text) async {
    if (text.isEmpty || _loading) return;
    final sendRecommendationCard = _wantsRecommendation(text);

    setState(() {
      _messages.add(_Msg(role: _Role.user, text: text));
      _loading = true;
    });
    _controller.clear();
    _scrollDown();

    final response = await _aiService.getRecommendation(text, kZones);

    setState(() {
      _messages.add(_Msg(role: _Role.ai, text: response));
      if (sendRecommendationCard) {
        _messages.add(_Msg(role: _Role.zoneCard, zone: _pickRecommendedZone()));
      }
      _loading = false;
    });
    _scrollDown();
  }

  Future<void> _send() => _sendText(_controller.text.trim());

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
        if (msg.role == _Role.ai) {
          return _AiBubble(text: msg.text, colors: c);
        }
        if (msg.role == _Role.zoneCard && msg.zone != null) {
          return _ZoneCard(
            zone: msg.zone!,
            colors: c,
            onRoute: () {
              context.read<AppController>().goToMap(routeTo: msg.zone);
            },
          );
        }
        return const SizedBox.shrink();
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
// Preset chip widget
// ---------------------------------------------------------------------------

class _PresetChip extends StatelessWidget {
  final String label;
  final JailooColors colors;
  final VoidCallback onTap;
  const _PresetChip({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
          ),
        ),
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
      duration: const Duration(milliseconds: 1200),
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

// ---------------------------------------------------------------------------
// Zone recommendation card
// ---------------------------------------------------------------------------

class _ZoneCard extends StatelessWidget {
  final Zone zone;
  final JailooColors colors;
  final VoidCallback onRoute;
  const _ZoneCard({
    required this.zone,
    required this.colors,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = JailooColors.statusColor(zone.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(Icons.landscape, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  'Рекомендую',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      zone.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      zone.nameEn,
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Health bar
                HealthBar(value: zone.healthScore / 100),
                const SizedBox(height: 2),
                Text(
                  'Здоровье: ${zone.healthScore}/100',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
                const SizedBox(height: 10),
                // Stats row
                Row(
                  children: [
                    _Stat(icon: Icons.pets, label: '${zone.maxHerd} овец', colors: colors),
                    const SizedBox(width: 16),
                    _Stat(icon: Icons.calendar_today, label: '${zone.safeDays} дней', colors: colors),
                    const SizedBox(width: 16),
                    _Stat(icon: Icons.straighten, label: '${zone.areaKm2.toInt()} км²', colors: colors),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  zone.elevation,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
                const SizedBox(height: 14),
                // Route button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRoute,
                    style: FilledButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text(
                      'Проложить маршрут',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final JailooColors colors;
  const _Stat({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: colors.textPrimary)),
      ],
    );
  }
}
