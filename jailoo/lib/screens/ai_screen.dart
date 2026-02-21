import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/zones.dart';
import '../models/zone.dart';
import '../models/herder_profile.dart';
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

  @override
  void dispose() {
    _scroll.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Best zone logic
  // ---------------------------------------------------------------------------

  Zone? _findBestZone(HerderProfile profile) {
    final candidates = kZones.where((z) => z.status == 'healthy').toList();
    if (candidates.isEmpty) return null;

    // Filter by capacity (sheep units vs maxHerd)
    final capable = candidates.where((z) => z.maxHerd >= profile.sheepUnits).toList();
    final pool = capable.isNotEmpty ? capable : candidates;

    // Sort by distance from the user's location
    pool.sort((a, b) {
      final da = _degDist(a.lat, a.lng);
      final db = _degDist(b.lat, b.lng);
      return da.compareTo(db);
    });
    return pool.first;
  }

  double _degDist(double lat, double lng) {
    const uLat = 41.43, uLng = 75.99;
    final dlat = lat - uLat, dlng = lng - uLng;
    return sqrt(dlat * dlat + dlng * dlng);
  }

  String _kmStr(double lat, double lng) {
    const uLat = 41.43, uLng = 75.99;
    const R = 111.32; // km per degree at this latitude
    final dlat = lat - uLat, dlng = lng - uLng;
    final km = sqrt(dlat * dlat * R * R + dlng * dlng * R * R);
    return '${km.round()} km';
  }

  Future<void> _findBestZoneAction() async {
    if (_thinking) return;

    final profile = context.read<HerderProfile>();

    setState(() {
      _thinking = true;
      _messages.add(_Message(
        role: 'user',
        text: 'Find the best grazing zone for my herd',
      ));
    });
    _scrollDown();

    // Simulate a brief "thinking" delay for realism
    await Future.delayed(const Duration(milliseconds: 1200));

    final zone = _findBestZone(profile);

    String response;
    if (zone == null) {
      response =
          'No healthy zones are currently available in your area. '
          'All zones are either banned or recovering. '
          'Please check back later or contact the regional office.';
      setState(() {
        _messages.add(_Message(role: 'ai', text: response));
        _thinking = false;
      });
    } else {
      final dist = _kmStr(zone.lat, zone.lng);
      final capacity = zone.maxHerd >= profile.sheepUnits
          ? '✓ Fits your herd (${profile.sheepUnits} sheep units)'
          : '⚠ At capacity limit — reduce herd size if possible';

      setState(() {
        _messages.add(_Message(
          role: 'ai',
          text: '',
          zoneCard: _ZoneRecommendation(
            zone: zone,
            distance: dist,
            capacity: capacity,
            herdNote:
                profile.total == 0
                    ? 'Set your herd size in the Me tab for better recommendations.'
                    : 'Based on ${profile.total} animals (${profile.sheepUnits} sheep units).',
          ),
        ));
        _thinking = false;
      });
    }

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
          _buildBestZoneButton(c),
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
                Text(
                  '🌿',
                  style: const TextStyle(fontSize: 40),
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
                  'Press the button below to find the best available zone for your herd right now.',
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
        if (msg.zoneCard != null) return _ZoneCardBubble(rec: msg.zoneCard!, c: c);
        return _Bubble(isUser: msg.role == 'user', text: msg.text, c: c);
      },
    );
  }

  Widget _buildBestZoneButton(JailooColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _thinking ? c.surface2 : c.accent,
            foregroundColor: _thinking ? c.textMuted : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: _thinking ? null : _findBestZoneAction,
          child: _thinking
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Analyzing zones…',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Best zone for me',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
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
  final _ZoneRecommendation? zoneCard;
  const _Message({required this.role, required this.text, this.zoneCard});
}

class _ZoneRecommendation {
  final Zone zone;
  final String distance;
  final String capacity;
  final String herdNote;
  const _ZoneRecommendation({
    required this.zone,
    required this.distance,
    required this.capacity,
    required this.herdNote,
  });
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

class _ZoneCardBubble extends StatelessWidget {
  final _ZoneRecommendation rec;
  final JailooColors c;
  const _ZoneCardBubble({required this.rec, required this.c});

  @override
  Widget build(BuildContext context) {
    final zone = rec.zone;
    final statusColor = JailooColors.statusColor(zone.status);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: c.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Best zone for you',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Zone card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        zone.nameEn,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${zone.healthScore}/100',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ZoneInfoRow(
                    icon: Icons.place_outlined,
                    text: '${rec.distance} from your location',
                    c: c,
                  ),
                  const SizedBox(height: 5),
                  _ZoneInfoRow(
                    icon: Icons.terrain_outlined,
                    text: zone.elevation,
                    c: c,
                  ),
                  const SizedBox(height: 5),
                  _ZoneInfoRow(
                    icon: Icons.people_outline,
                    text: 'Up to ${zone.maxHerd} sheep · ${rec.capacity}',
                    c: c,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.bg.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: c.border),
                    ),
                    child: Text(
                      zone.seasonNote,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Footer note
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                rec.herdNote,
                style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final JailooColors c;
  const _ZoneInfoRow({required this.icon, required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

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
            content: const Text('Manual prompts coming soon — use the button below'),
            backgroundColor: c.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
