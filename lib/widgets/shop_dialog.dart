import 'package:flutter/material.dart';
import '../models/game_state.dart';

// ─── Shop item definition ─────────────────────────────────────────────────────

class _ShopItem {
  final String name;
  final String effect;
  final int cost;
  final void Function(GameState) apply;
  _ShopItem(this.name, this.effect, this.cost, this.apply);
}

List<_ShopItem> _buildCatalog() => [
      _ShopItem('Fuel Canister', '+25 FUEL', 30,
          (gs) { gs.fuel = (gs.fuel + 25).clamp(0, gs.maxFuel); }),
      _ShopItem('Ration Pack', '+20 RATIONS', 25,
          (gs) { gs.rations = (gs.rations + 20).clamp(0, gs.maxRations); }),
      _ShopItem('O2 Filter Pack', '+25 OXYGEN', 35,
          (gs) { gs.oxygen = (gs.oxygen + 25).clamp(0, gs.maxOxygen); }),
      _ShopItem('Ammo Crate', '+20 AMMO', 20,
          (gs) { gs.ammo = (gs.ammo + 20).clamp(0, 100); }),
      _ShopItem('Med Supplies', '+20 MEDICINE', 28,
          (gs) { gs.medicine = (gs.medicine + 20).clamp(0, 100); }),
      _ShopItem('Hull Repair Kit', '+15 HULL', 45,
          (gs) { gs.hull = (gs.hull + 15).clamp(0, gs.maxHull); }),
      _ShopItem('Salvage Cache', '+15 SALVAGE', 22,
          (gs) { gs.salvage = (gs.salvage + 15).clamp(0, 999); }),
      _ShopItem('Crew Morale Boost', 'CREW LOYALTY +8', 40, (gs) {
        for (final c in gs.crew.where((c) => c.isAlive)) {
          c.loyalty = (c.loyalty + 8).clamp(0, 100);
        }
      }),
      _ShopItem('Alien Data Cache', 'ALL SPECIES KNOWLEDGE +10', 55, (gs) {
        for (final s in AlienSpecies.values) {
          gs.alienKnowledge[s] = ((gs.alienKnowledge[s] ?? 0) + 10).clamp(0, 100);
        }
      }),
    ];

// ─── Dialog ───────────────────────────────────────────────────────────────────

class ShopDialog extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onPurchase;
  const ShopDialog(
      {super.key, required this.gameState, required this.onPurchase});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  GameState get _gs => widget.gameState;
  late final List<_ShopItem> _catalog = _buildCatalog();

  void _buy(_ShopItem item) {
    if (_gs.credits < item.cost) return;
    setState(() {
      _gs.credits -= item.cost;
      item.apply(_gs);
      _gs.addLog('Purchased: ${item.name}');
    });
    widget.onPurchase();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF040814),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          border:
              Border.all(color: const Color(0xFF00DDCC).withAlpha(150), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(children: [
              const Text('TRADE POST',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 4,
                      color: Color(0xFF00DDCC),
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFFFFDD44).withAlpha(120)),
                  color: const Color(0xFFFFDD44).withAlpha(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('₢ ',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFFFFDD44))),
                  Text('${_gs.credits}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFDD44))),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('AVAILABLE GOODS',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
            const SizedBox(height: 12),
            Container(
                height: 1, color: const Color(0xFF00DDCC).withAlpha(60)),
            const SizedBox(height: 10),
            // ── Item list ───────────────────────────────────────────────────
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  children: _catalog
                      .map((item) => _ItemRow(
                            item: item,
                            canAfford: _gs.credits >= item.cost,
                            onBuy: () => _buy(item),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Close ───────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00DDCC)),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: const Text('LEAVE MARKET',
                    style: TextStyle(
                        letterSpacing: 3,
                        color: Color(0xFF00DDCC),
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single item row ──────────────────────────────────────────────────────────

class _ItemRow extends StatefulWidget {
  final _ShopItem item;
  final bool canAfford;
  final VoidCallback onBuy;
  const _ItemRow(
      {required this.item, required this.canAfford, required this.onBuy});

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00DDCC);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        // Name + effect
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.canAfford
                            ? Colors.white
                            : Colors.white.withAlpha(80))),
                Text(widget.item.effect,
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        color: Colors.white.withAlpha(100))),
              ]),
        ),
        // Price
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('₢${widget.item.cost}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.canAfford
                      ? const Color(0xFFFFDD44)
                      : Colors.white.withAlpha(50))),
        ),
        // Buy button
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.canAfford ? widget.onBuy : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(
                    color: widget.canAfford
                        ? (_hovered ? teal : teal.withAlpha(120))
                        : Colors.white.withAlpha(25)),
                color: widget.canAfford && _hovered
                    ? teal.withAlpha(25)
                    : Colors.transparent,
              ),
              child: Text('BUY',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: widget.canAfford
                          ? teal
                          : Colors.white.withAlpha(30))),
            ),
          ),
        ),
      ]),
    );
  }
}
