import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'add_pasture_screen.dart';

// ---------------------------------------------------------------------------
// Mock user data — replace with real persistence/backend later
// ---------------------------------------------------------------------------

class _Livestock {
  final String label;
  final int count;
  const _Livestock({required this.label, required this.count});
}

const _kLivestock = [
  _Livestock(label: 'Овцы',   count: 340),
  _Livestock(label: 'Козы',   count: 85),
  _Livestock(label: 'Коровы', count: 24),
  _Livestock(label: 'Лошади', count: 18),
];

const _kTotalAreaHa = 1470.0;
const _kActivePastures = 3;
const _kUserName = 'Кутман Асанов';
const _kVillage = 'с. Кок-Жар, Нарынская обл.';

// ---------------------------------------------------------------------------

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _ProfileHeader(c: c)),

            // ── Stats row ─────────────────────────────────────────────────
            SliverToBoxAdapter(child: _StatsRow(c: c)),

            // ── Section title ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  'Поголовье скота',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontFamily: 'DMMono',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // ── Livestock cards ───────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: _kLivestock
                    .map((l) => _LivestockCard(item: l, c: c))
                    .toList(),
              ),
            ),

            // ── Section title ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Text(
                  'Пастбища',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontFamily: 'DMMono',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // ── My pastures list ──────────────────────────────────────────
            SliverToBoxAdapter(child: _MyPasturesList(c: c)),

            // ── Add pasture button ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: _AddPastureButton(c: c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final JailooColors c;
  const _ProfileHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: c.accent.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                _kUserName.split(' ').map((w) => w[0]).take(2).join(),
                style: TextStyle(
                  color: c.accent,
                  fontSize: 20,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name & village
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _kUserName,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontFamily: 'DMMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _kVillage,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                    fontFamily: 'DMMono',
                  ),
                ),
              ],
            ),
          ),
          // Edit icon
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.edit_outlined, color: c.textMuted, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row (total animals, area, active pastures)
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final JailooColors c;
  const _StatsRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final totalAnimals = _kLivestock.fold(0, (s, l) => s + l.count);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatChip(
            c: c,
            value: '$totalAnimals',
            label: 'Всего голов',
            icon: Icons.pets,
          ),
          const SizedBox(width: 10),
          _StatChip(
            c: c,
            value: '${_kTotalAreaHa.toStringAsFixed(0)} га',
            label: 'Площадь',
            icon: Icons.landscape_outlined,
          ),
          const SizedBox(width: 10),
          _StatChip(
            c: c,
            value: '$_kActivePastures',
            label: 'Пастбищ',
            icon: Icons.grass_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final JailooColors c;
  final String value;
  final String label;
  final IconData icon;
  const _StatChip({required this.c, required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.accent, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontFamily: 'DMMono',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 10,
                fontFamily: 'DMMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Livestock card
// ---------------------------------------------------------------------------

class _LivestockCard extends StatelessWidget {
  final _Livestock item;
  final JailooColors c;
  const _LivestockCard({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.count}',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontFamily: 'DMMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.label,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontFamily: 'DMMono',
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

// ---------------------------------------------------------------------------
// My pastures list (hardcoded mock — in production comes from local DB)
// ---------------------------------------------------------------------------

class _MyPastureData {
  final String name;
  final double areaHa;
  final String status;
  const _MyPastureData({required this.name, required this.areaHa, required this.status});
}

final _kMyPastures = [
  _MyPastureData(name: 'Летнее пастбище',    areaHa: 620,  status: 'healthy'),
  _MyPastureData(name: 'Осеннее пастбище',   areaHa: 490,  status: 'recovering'),
  _MyPastureData(name: 'Зимнее укрытие',     areaHa: 360,  status: 'healthy'),
];

class _MyPasturesList extends StatelessWidget {
  final JailooColors c;
  const _MyPasturesList({required this.c});

  Color _statusColor(String s) => JailooColors.statusColor(s);
  String _statusLabel(String s) {
    switch (s) {
      case 'healthy':    return 'Хорошее';
      case 'recovering': return 'Восстан.';
      case 'banned':     return 'Запрет';
      default:           return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _kMyPastures.map((p) {
          final color = _statusColor(p.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13,
                          fontFamily: 'DMMono',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.areaHa.toStringAsFixed(0)} га',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 11,
                          fontFamily: 'DMMono',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(p.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontFamily: 'DMMono',
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add pasture button
// ---------------------------------------------------------------------------

class _AddPastureButton extends StatelessWidget {
  final JailooColors c;
  const _AddPastureButton({required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddPastureScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Text(
              'Добавить пастбище',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'DMMono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
