import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/herder_profile.dart';
import '../theme/colors.dart';
import '../theme/theme_provider.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final profile = context.watch<HerderProfile>();

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        slivers: [
          _ProfileAppBar(c: c, profile: profile),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16, 0, 16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel(label: 'My Herd', c: c),
                _HerdGrid(profile: profile, c: c),
                const SizedBox(height: 12),
                _HerdSummaryCard(profile: profile, c: c),
                _SectionLabel(label: 'Grazing Season', c: c),
                _SeasonCard(c: c),
                _SectionLabel(label: 'Settings', c: c),
                _SettingsCard(c: c),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar with profile header
// ---------------------------------------------------------------------------

class _ProfileAppBar extends StatelessWidget {
  final JailooColors c;
  final HerderProfile profile;
  const _ProfileAppBar({required this.c, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: c.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: c.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  profile.region,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Total herd pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🐑 ',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${profile.total}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
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
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  final JailooColors c;
  const _SectionLabel({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: c.textMuted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Herd grid — 2-column grid of animal counters
// ---------------------------------------------------------------------------

class _HerdGrid extends StatelessWidget {
  final HerderProfile profile;
  final JailooColors c;
  const _HerdGrid({required this.profile, required this.c});

  @override
  Widget build(BuildContext context) {
    final animals = [
      _Animal('sheep', '🐑', 'Sheep', profile.sheep),
      _Animal('goats', '🐐', 'Goats', profile.goats),
      _Animal('horses', '🐴', 'Horses', profile.horses),
      _Animal('cattle', '🐄', 'Cattle', profile.cattle),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: animals
          .map((a) => _AnimalCard(animal: a, profile: profile, c: c))
          .toList(),
    );
  }
}

class _Animal {
  final String key;
  final String emoji;
  final String label;
  final int count;
  const _Animal(this.key, this.emoji, this.label, this.count);
}

class _AnimalCard extends StatelessWidget {
  final _Animal animal;
  final HerderProfile profile;
  final JailooColors c;
  const _AnimalCard({
    required this.animal,
    required this.profile,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(animal.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                animal.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CounterButton(
                icon: Icons.remove,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<HerderProfile>().decrement(animal.key);
                },
                c: c,
              ),
              Text(
                '${animal.count}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              _CounterButton(
                icon: Icons.add,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<HerderProfile>().increment(animal.key);
                },
                c: c,
                accent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final JailooColors c;
  final bool accent;
  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.c,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accent
              ? c.accent.withValues(alpha: 0.1)
              : c.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent
                ? c.accent.withValues(alpha: 0.3)
                : c.border,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: accent ? c.accent : c.textMuted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Herd summary card
// ---------------------------------------------------------------------------

class _HerdSummaryCard extends StatelessWidget {
  final HerderProfile profile;
  final JailooColors c;
  const _HerdSummaryCard({required this.profile, required this.c});

  @override
  Widget build(BuildContext context) {
    final units = profile.sheepUnits;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Text(
                'Herd Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryPill(
                label: 'Total animals',
                value: '${profile.total}',
                c: c,
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                label: 'Sheep units',
                value: '$units',
                c: c,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You need a pasture zone with capacity ≥ $units sheep units.',
            style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final JailooColors c;
  const _SummaryPill({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.bg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Season card
// ---------------------------------------------------------------------------

class _SeasonCard extends StatefulWidget {
  final JailooColors c;
  const _SeasonCard({required this.c});

  @override
  State<_SeasonCard> createState() => _SeasonCardState();
}

class _SeasonCardState extends State<_SeasonCard> {
  int _selected = 1; // 0=Spring 1=Summer 2=Autumn

  static const _seasons = [
    ('Spring', '🌱', 'Apr–May · Low elevation'),
    ('Summer', '☀️', 'Jun–Sep · Alpine meadows'),
    ('Autumn', '🍂', 'Sep–Oct · Valley pastures'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: _seasons.indexed.map((entry) {
          final idx = entry.$1;
          final s = entry.$2;
          final selected = idx == _selected;
          final isLast = idx == _seasons.length - 1;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selected = idx);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: selected ? c.accent.withValues(alpha: 0.07) : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(11) : Radius.zero,
                  bottom: isLast ? const Radius.circular(11) : Radius.zero,
                ),
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Text(s.$2, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? c.accent : c.textPrimary,
                          ),
                        ),
                        Text(
                          s.$3,
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 18, color: c.accent),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings card
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  final JailooColors c;
  const _SettingsCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: isDark ? 'Light mode' : 'Dark mode',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => context.read<ThemeProvider>().toggle(),
              activeThumbColor: c.accent,
              activeTrackColor: c.accent.withValues(alpha: 0.3),
            ),
            c: c,
            isLast: false,
          ),
          _SettingsRow(
            icon: Icons.language_outlined,
            label: 'Language',
            trailing: Text(
              'Русский',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
            c: c,
            isLast: false,
          ),
          _SettingsRow(
            icon: Icons.info_outline,
            label: 'App version',
            trailing: Text(
              '1.0.0-beta',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
            c: c,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final JailooColors c;
  final bool isLast;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.c,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.textPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
