import 'package:flutter/material.dart';
import '../models/game_state.dart';

// ─── Research & Upgrade Dialog ────────────────────────────────────────────────

class ResearchDialog extends StatefulWidget {
  final GameState gs;
  final VoidCallback onChanged;

  const ResearchDialog({super.key, required this.gs, required this.onChanged});

  @override
  State<ResearchDialog> createState() => _ResearchDialogState();
}

class _ResearchDialogState extends State<ResearchDialog> {
  GameState get _gs => widget.gs;

  void _buy(String upgradeKey, String name, int currentLevel) {
    final ok = _gs.purchaseUpgrade(upgradeKey);
    if (ok) {
      setState(() {});
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF040814),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00DDCC).withAlpha(130)),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                border: Border(
                  bottom: BorderSide(
                      color: const Color(0xFF00DDCC).withAlpha(50)),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UES VEKTARA  •  RESEARCH TERMINAL',
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 4,
                            color: Color(0xFF00DDCC),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'SHIP UPGRADES',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Credits display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFFFDD44).withAlpha(140)),
                      color: const Color(0xFFFFDD44).withAlpha(10),
                    ),
                    child: Column(
                      children: [
                        const Text('CREDITS',
                            style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 2,
                                color: Color(0xFFFFDD44))),
                        Text(
                          '₢${_gs.credits}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFDD44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Upgrade list ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _CategorySection(
                      title: 'HULL & DEFENSE',
                      icon: '◈',
                      color: const Color(0xFF00FF88),
                      items: [
                        _UpgradeItem(
                          upgradeKey: 'hull',
                          name: 'Hull Plating',
                          level: _gs.upgrades.hullPlating,
                          tiers: const [
                            'Reduces hull damage per encounter by 5.',
                            'Reduces hull damage per encounter by 10.',
                            'Reduces hull damage per encounter by 15.',
                          ],
                          onBuy: _buy,
                          credits: _gs.credits,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CategorySection(
                      title: 'PROPULSION',
                      icon: '▶',
                      color: const Color(0xFF00AAFF),
                      items: [
                        _UpgradeItem(
                          upgradeKey: 'drive',
                          name: 'Drive Core',
                          level: _gs.upgrades.driveCore,
                          tiers: const [
                            'Saves 1 fuel per node jump.',
                            'Saves 2 fuel per node jump.',
                            'Saves 3 fuel per node jump.',
                          ],
                          onBuy: _buy,
                          credits: _gs.credits,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CategorySection(
                      title: 'LIFE SUPPORT',
                      icon: '◉',
                      color: const Color(0xFF44DDFF),
                      items: [
                        _UpgradeItem(
                          upgradeKey: 'med',
                          name: 'Med Bay',
                          level: _gs.upgrades.medBay,
                          tiers: const [
                            'Heals 3 crew trauma per sector.',
                            'Heals 6 crew trauma per sector.',
                            'Heals 10 crew trauma per sector.',
                          ],
                          onBuy: _buy,
                          credits: _gs.credits,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CategorySection(
                      title: 'CREW SYSTEMS',
                      icon: '◆',
                      color: const Color(0xFFFFAA00),
                      items: [
                        _UpgradeItem(
                          upgradeKey: 'quarters',
                          name: 'Crew Quarters',
                          level: _gs.upgrades.crewQuarters,
                          tiers: const [
                            'Crew hope +2 per sector.',
                            'Crew hope +4 per sector.',
                            'Crew hope +6 per sector.',
                          ],
                          onBuy: _buy,
                          credits: _gs.credits,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CategorySection(
                      title: 'WEAPONS',
                      icon: '✦',
                      color: const Color(0xFFCC88FF),
                      items: [
                        _UpgradeItem(
                          upgradeKey: 'weapons',
                          name: 'Weapons Array',
                          level: _gs.upgrades.weaponsArray,
                          tiers: const [
                            '+10 ammo capacity. Combat outcomes improved.',
                            '+20 ammo capacity. Significant combat advantage.',
                            '+30 ammo capacity. Superior firepower.',
                          ],
                          onBuy: _buy,
                          credits: _gs.credits,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CategorySection(
                      title: 'INTELLIGENCE',
                      icon: '⬡',
                      color: const Color(0xFFFF8844),
                      items: [
                        _UpgradeItem(
                          upgradeKey: 'research',
                          name: 'Research Terminal',
                          level: _gs.upgrades.researchTerminal,
                          tiers: const [
                            '+5 alien knowledge per sector (all species).',
                            '+10 alien knowledge per sector (all species).',
                            '+15 alien knowledge per sector. Unlocks hidden encounter options.',
                          ],
                          onBuy: _buy,
                          credits: _gs.credits,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: const Color(0xFF00DDCC).withAlpha(40)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Upgrades persist for the run.  Salvage: ${_gs.salvage} units',
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        color: Colors.white.withAlpha(50)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00DDCC)),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(
                        letterSpacing: 3,
                        fontSize: 11,
                        color: Color(0xFF00DDCC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category section ─────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String title;
  final String icon;
  final Color color;
  final List<_UpgradeItem> items;

  const _CategorySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            color: color.withAlpha(18),
            child: Row(children: [
              Text(icon,
                  style: TextStyle(fontSize: 12, color: color)),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ]),
          ),
          ...items,
        ],
      ),
    );
  }
}

// ─── Single upgrade row ───────────────────────────────────────────────────────

class _UpgradeItem extends StatelessWidget {
  final String upgradeKey;
  final String name;
  final int level; // 0–3
  final List<String> tiers; // 3 descriptions
  final int credits;
  final void Function(String upgradeKey, String name, int level) onBuy;

  const _UpgradeItem({
    required this.upgradeKey,
    required this.name,
    required this.level,
    required this.tiers,
    required this.credits,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final maxed = level >= 3;
    final cost = maxed ? 0 : GameState.upgradeCost(level);
    final canAfford = !maxed && credits >= cost;
    final nextDesc = maxed ? 'FULLY UPGRADED' : tiers[level];
    const accent = Color(0xFF00DDCC);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Name + tier dots
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      ...List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i < level
                                ? accent
                                : Colors.transparent,
                            border: Border.all(
                              color: i < level
                                  ? accent
                                  : Colors.white.withAlpha(35),
                            ),
                          ),
                        ),
                      )),
                      if (maxed) ...[
                        const SizedBox(width: 8),
                        Text('MAX',
                            style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 2,
                                color: accent.withAlpha(180))),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      nextDesc,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: maxed
                            ? Colors.white.withAlpha(50)
                            : Colors.white.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Buy button
              if (!maxed)
                _BuyBtn(
                  cost: cost,
                  canAfford: canAfford,
                  onTap: () => onBuy(upgradeKey, name, level),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuyBtn extends StatefulWidget {
  final int cost;
  final bool canAfford;
  final VoidCallback onTap;
  const _BuyBtn({required this.cost, required this.canAfford, required this.onTap});

  @override
  State<_BuyBtn> createState() => _BuyBtnState();
}

class _BuyBtnState extends State<_BuyBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFDD44);
    final active = widget.canAfford && _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.canAfford ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.canAfford
                  ? (active ? accent : accent.withAlpha(140))
                  : Colors.white.withAlpha(25),
            ),
            color: active ? accent.withAlpha(20) : Colors.transparent,
          ),
          child: Column(
            children: [
              Text(
                'RESEARCH',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: widget.canAfford
                      ? (active ? Colors.white : accent)
                      : Colors.white.withAlpha(30),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₢${widget.cost}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.canAfford
                      ? accent
                      : Colors.white.withAlpha(30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
