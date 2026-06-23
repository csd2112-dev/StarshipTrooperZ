import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/encounter.dart';
import '../engine/encounter_engine.dart';
import '../widgets/starfield_painter.dart';
import 'title_screen.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _starCtrl;
  late final List<StarData> _stars;
  late final GameState _gs;

  final Set<String> _playedIds = {};
  int _encountersThisSector = 0;
  static const int _encountersPerSector = 3;

  bool _isPaused = false;

  bool get _canAdvanceSector =>
      _encountersThisSector >= _encountersPerSector && !_gs.isGameOver;

  @override
  void initState() {
    super.initState();
    _gs = widget.gameState;
    _stars = generateStars(120, seed: 99);
    _starCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 70))
          ..repeat();
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  void _triggerEncounter() {
    final encounter = EncounterEngine.pick(_gs, _playedIds);
    if (encounter == null) {
      setState(() {
        _gs.addLog('No further contacts in this sector. Advance when ready.');
        _encountersThisSector = _encountersPerSector; // force sector advance
      });
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EncounterDialog(
        encounter: encounter,
        gameState: _gs,
        onResolved: (choice) {
          setState(() {
            _playedIds.add(encounter.id);
            EncounterEngine.apply(_gs, choice);
            _gs.addLog(encounter.title);
            _gs.day++;
            _encountersThisSector++;
          });
        },
      ),
    );
  }

  void _advanceSector() {
    setState(() {
      EncounterEngine.advanceSector(_gs);
      _encountersThisSector = 0;
    });
    if (_gs.isGameOver) _showGameOver();
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameOverDialog(
        gameState: _gs,
        onMainMenu: _goToTitle,
      ),
    );
  }

  void _goToTitle() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const TitleScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (route) => false,
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          setState(() => _isPaused = !_isPaused);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _starCtrl,
              builder: (_, __) => CustomPaint(
                painter: StarfieldPainter(stars: _stars, offset: _starCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: LayoutBuilder(builder: (ctx, c) {
                      return c.maxWidth > 750
                          ? _buildWideLayout()
                          : _buildNarrowLayout();
                    }),
                  ),
                  _buildActionBar(),
                ],
              ),
            ),
            if (_isPaused) _PauseMenu(
              onResume: () => setState(() => _isPaused = false),
              onNewGame: _goToTitle,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        border: Border(bottom: BorderSide(color: const Color(0xFF00FF88).withAlpha(80))),
      ),
      child: Row(
        children: [
          _SectorDots(current: _gs.sector),
          const SizedBox(width: 12),
          Text('SECTOR ${_gs.sector} / 5',
              style: const TextStyle(fontSize: 11, letterSpacing: 3, color: Color(0xFF00FF88))),
          const Spacer(),
          Text('DAY ${_gs.day}',
              style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white.withAlpha(140))),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CMD. ${_gs.commanderName.toUpperCase()}',
                  style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
              Text(_gs.background.displayName.toUpperCase(),
                  style: TextStyle(fontSize: 9, letterSpacing: 2, color: Colors.white.withAlpha(100))),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _isPaused = !_isPaused),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withAlpha(60)),
              ),
              child: Icon(Icons.menu, size: 16, color: Colors.white.withAlpha(160)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Layouts ─────────────────────────────────────────────────────────────────

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 260,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              _buildShipPanel(),
              const SizedBox(height: 10),
              _buildOrderPanel(),
              const SizedBox(height: 10),
              _buildPsychPanel(),
              const SizedBox(height: 10),
              _buildUpgradesPanel(),
            ]),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              _buildCrewPanel(),
              const SizedBox(height: 10),
              _buildAlienPanel(),
              const SizedBox(height: 10),
              _buildLogPanel(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        _buildShipPanel(),
        const SizedBox(height: 10),
        _buildOrderPanel(),
        const SizedBox(height: 10),
        _buildCrewPanel(),
        const SizedBox(height: 10),
        _buildPsychPanel(),
        const SizedBox(height: 10),
        _buildAlienPanel(),
        const SizedBox(height: 10),
        _buildUpgradesPanel(),
        const SizedBox(height: 10),
        _buildLogPanel(),
      ]),
    );
  }

  // ─── Panels ──────────────────────────────────────────────────────────────────

  Widget _buildShipPanel() {
    return _Panel(
      title: 'SHIP STATUS',
      child: Column(children: [
        _StatBar(label: 'HULL', value: _gs.hull, max: _gs.maxHull, color: _healthColor(_gs.hull, _gs.maxHull)),
        _StatBar(label: 'FUEL', value: _gs.fuel, max: _gs.maxFuel, color: const Color(0xFF00AAFF)),
        _StatBar(label: 'RATIONS', value: _gs.rations, max: _gs.maxRations, color: const Color(0xFFFFAA00)),
        _StatBar(label: 'AMMO', value: _gs.ammo, max: 100, color: const Color(0xFFCC88FF)),
        _StatBar(label: 'MEDICINE', value: _gs.medicine, max: 100, color: const Color(0xFF00DDCC)),
        const SizedBox(height: 4),
        Row(children: [
          Text('SALVAGE', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white.withAlpha(140))),
          const Spacer(),
          Text('${_gs.salvage}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFDD44))),
          Text('  units', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(80))),
        ]),
      ]),
    );
  }

  Color _healthColor(int val, int max) {
    final pct = val / max;
    if (pct > 0.6) return const Color(0xFF00FF88);
    if (pct > 0.3) return const Color(0xFFFFAA00);
    return const Color(0xFFFF4444);
  }

  Widget _buildOrderPanel() {
    final tColor = _gs.civilianTension < 25
        ? const Color(0xFF00FF88)
        : _gs.civilianTension < 60
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF4444);

    return _Panel(
      title: 'SHIP ORDER',
      child: Column(children: [
        _StatBar(label: 'ORDER LEVEL', value: _gs.orderLevel, max: 100, color: const Color(0xFF00FF88)),
        const SizedBox(height: 8),
        Row(children: [
          Text('CIV. TENSION', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white.withAlpha(140))),
          const Spacer(),
          _Badge(label: _gs.tensionLabel, color: tColor),
        ]),
        const SizedBox(height: 6),
        _StatBar(label: '', value: _gs.civilianTension, max: 100, color: tColor),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _CrewCount('CITIZENS', _gs.citizenCount, const Color(0xFF00AAFF)),
          Container(width: 1, height: 28, color: Colors.white.withAlpha(30)),
          _CrewCount('CIVILIANS', _gs.civilianCount, const Color(0xFFFFAA00)),
          Container(width: 1, height: 28, color: Colors.white.withAlpha(30)),
          _CrewCount('TOTAL', _gs.aliveCount, Colors.white),
        ]),
      ]),
    );
  }

  Widget _buildPsychPanel() {
    return _Panel(
      title: 'COMMANDER PSYCH',
      child: Column(children: [
        _StatBar(label: 'RESOLVE', value: _gs.psychology.resolve, max: 100, color: const Color(0xFF00FF88)),
        _StatBar(label: 'EMPATHY', value: _gs.psychology.empathy, max: 100, color: const Color(0xFF00AAFF)),
        _StatBar(label: 'AUTHORITY', value: _gs.psychology.authority, max: 100, color: const Color(0xFFCC88FF)),
        const SizedBox(height: 8),
        _LabelRow('STATUS', _gs.psychology.resolveLabel, const Color(0xFF00FF88)),
        const SizedBox(height: 4),
        _LabelRow(
          'ACCORD',
          _gs.psychology.reputationLabel,
          _gs.psychology.reputation >= 0 ? const Color(0xFF00AAFF) : const Color(0xFFFF4444),
        ),
        const SizedBox(height: 4),
        _LabelRow(
          'BUG SYMPATHY',
          _gs.psychology.bugSympathy < 10 ? '??? CLASSIFIED' : '${_gs.psychology.bugSympathy}%',
          Colors.white.withAlpha(_gs.psychology.bugSympathy < 10 ? 60 : 220),
        ),
      ]),
    );
  }

  Widget _buildCrewPanel() {
    final alive = _gs.crew.where((c) => c.isAlive).toList();
    return _Panel(
      title: 'CREW MANIFEST',
      child: Column(
        children: alive.map((c) {
          final isCitizen = c.status == CrewStatus.citizen;
          final sColor = isCitizen ? const Color(0xFF00AAFF) : const Color(0xFFFFAA00);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(c.role, style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120))),
                  ]),
                ),
                _Badge(label: c.statusLabel, color: sColor),
              ]),
              const SizedBox(height: 5),
              Row(children: [
                Expanded(child: _MiniBar(value: c.loyalty / 100, color: const Color(0xFF00FF88))),
                const SizedBox(width: 8),
                Text(c.loyaltyLabel, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(120))),
              ]),
              if (c.trauma > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('⚠ Trauma ${c.trauma}%',
                      style: const TextStyle(fontSize: 9, color: Color(0xFFFF8844))),
                ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlienPanel() {
    return _Panel(
      title: 'ALIEN DATABASE',
      child: Column(
        children: AlienSpecies.values.map((s) {
          final k = _gs.alienKnowledge[s] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(s.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$k%', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120))),
              ]),
              const SizedBox(height: 3),
              _MiniBar(value: k / 100, color: const Color(0xFFCC88FF)),
              if (k < 15)
                Text('  Insufficient — contact classified',
                    style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(50))),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpgradesPanel() {
    final keys = ['hull', 'drive', 'med', 'quarters', 'weapons', 'research'];
    final names = ['Hull Plating', 'Drive Core', 'Med Bay', 'Quarters', 'Weapons', 'Research'];

    return _Panel(
      title: 'UPGRADES  •  10 salvage each',
      child: Column(
        children: List.generate(6, (i) {
          final lvl = _gs.upgrades.levelOf(i);
          final canBuy = _gs.salvage >= 10 && lvl < 3;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text(names[i], style: const TextStyle(fontSize: 11))),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (j) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: j < lvl ? const Color(0xFF00FF88) : Colors.transparent,
                      border: Border.all(
                        color: j < lvl ? const Color(0xFF00FF88) : Colors.white.withAlpha(40),
                      ),
                    ),
                  ),
                )),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: canBuy
                    ? () {
                        final newLvl = lvl + 1;
                        final ok = _gs.purchaseUpgrade(keys[i]);
                        if (ok) setState(() => _gs.addLog('${names[i]} upgraded to Mk.$newLvl.'));
                      }
                    : null,
                child: Opacity(
                  opacity: canBuy ? 1.0 : 0.25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFDD44).withAlpha(160)),
                    ),
                    child: const Text('BUY',
                        style: TextStyle(fontSize: 8, letterSpacing: 1, color: Color(0xFFFFDD44))),
                  ),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _buildLogPanel() {
    return _Panel(
      title: 'MISSION LOG',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _gs.missionLog.take(12).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('> $entry',
                  style: TextStyle(fontSize: 11, height: 1.4, color: Colors.white.withAlpha(160))),
            )).toList(),
      ),
    );
  }

  // ─── Action Bar ──────────────────────────────────────────────────────────────

  Widget _buildActionBar() {
    if (_gs.isGameOver) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        color: Colors.black.withAlpha(160),
        child: _ActionButton(
          label: '◉  MISSION COMPLETE — VIEW ENDING',
          color: const Color(0xFFFFDD44),
          onPressed: _showGameOver,
        ),
      );
    }
    if (_canAdvanceSector) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          border: Border(top: BorderSide(color: const Color(0xFFFFAA00).withAlpha(80))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_encountersThisSector of $_encountersPerSector encounters complete',
              style: TextStyle(fontSize: 9, letterSpacing: 2, color: Colors.white.withAlpha(80)),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: '▶▶  JUMP TO SECTOR ${_gs.sector + 1}',
              color: const Color(0xFFFFAA00),
              onPressed: _advanceSector,
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        border: Border(top: BorderSide(color: const Color(0xFF00FF88).withAlpha(60))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ENCOUNTER ${_encountersThisSector + 1} OF $_encountersPerSector',
            style: TextStyle(fontSize: 9, letterSpacing: 3, color: Colors.white.withAlpha(60)),
          ),
          const SizedBox(height: 8),
          _PulsingButton(
            label: '▶   PROCEED TO NEXT ENCOUNTER',
            onPressed: _triggerEncounter,
          ),
        ],
      ),
    );
  }
}

// ─── Pause Menu ───────────────────────────────────────────────────────────────

class _PauseMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onNewGame;
  const _PauseMenu({required this.onResume, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResume,
      child: Container(
        color: Colors.black.withAlpha(200),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {}, // absorb taps so clicking menu panel doesn't close
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF040814),
              border: Border.all(color: const Color(0xFF00FF88).withAlpha(160), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00FF88).withAlpha(30), blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('MISSION PAUSED',
                    style: TextStyle(fontSize: 11, letterSpacing: 6, color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
                const SizedBox(height: 28),
                _MenuBtn(label: 'RESUME MISSION', color: const Color(0xFF00FF88), onTap: onResume),
                const SizedBox(height: 12),
                _MenuBtn(label: 'NEW GAME', color: const Color(0xFF00AAFF), onTap: onNewGame),
                const SizedBox(height: 12),
                _MenuBtn(
                  label: 'EXIT TO TITLE',
                  color: Colors.white.withAlpha(160),
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, a, __) => const TitleScreen(),
                      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 600),
                    ),
                    (route) => false,
                  ),
                ),
                const SizedBox(height: 20),
                Text('ESC to close',
                    style: TextStyle(fontSize: 9, letterSpacing: 2, color: Colors.white.withAlpha(60))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuBtn({required this.label, required this.color, required this.onTap});

  @override
  State<_MenuBtn> createState() => _MenuBtnState();
}

class _MenuBtnState extends State<_MenuBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _hovered ? widget.color : widget.color.withAlpha(80)),
            color: _hovered ? widget.color.withAlpha(20) : Colors.transparent,
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: _hovered ? Colors.white : widget.color,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

// ─── Encounter Dialog ─────────────────────────────────────────────────────────

class _EncounterDialog extends StatefulWidget {
  final EncounterData encounter;
  final GameState gameState;
  final ValueChanged<EncounterChoice> onResolved;
  const _EncounterDialog({
    required this.encounter,
    required this.gameState,
    required this.onResolved,
  });

  @override
  State<_EncounterDialog> createState() => _EncounterDialogState();
}

class _EncounterDialogState extends State<_EncounterDialog> {
  EncounterChoice? _chosen;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF040814),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00FF88).withAlpha(120)),
        ),
        child: _chosen == null ? _buildPrompt() : _buildOutcome(context),
      ),
    );
  }

  Widget _buildPrompt() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.encounter.sectorTag,
              style: const TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF00FF88))),
          const SizedBox(height: 6),
          Text(widget.encounter.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
          const SizedBox(height: 16),
          Text(widget.encounter.story,
              style: const TextStyle(fontSize: 13, height: 1.75, color: Colors.white)),
          const SizedBox(height: 24),
          ...widget.encounter.choices.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceBtn(choice: c, onTap: () => setState(() => _chosen = c)),
              )),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.encounter.sectorTag,
              style: const TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF00FF88))),
          const SizedBox(height: 6),
          const Text('OUTCOME',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
          const SizedBox(height: 16),
          Text(_chosen!.outcome,
              style: const TextStyle(fontSize: 13, height: 1.75, color: Colors.white)),
          const SizedBox(height: 8),
          _buildStatDeltas(_chosen!),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onResolved(_chosen!);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00FF88)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('CONTINUE  →',
                  style: TextStyle(letterSpacing: 3, color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDeltas(EncounterChoice c) {
    final deltas = <(String, int)>[];
    if (c.hullDelta != 0) deltas.add(('Hull', c.hullDelta));
    if (c.fuelDelta != 0) deltas.add(('Fuel', c.fuelDelta));
    if (c.rationsDelta != 0) deltas.add(('Rations', c.rationsDelta));
    if (c.ammoDelta != 0) deltas.add(('Ammo', c.ammoDelta));
    if (c.medicineDelta != 0) deltas.add(('Medicine', c.medicineDelta));
    if (c.salvageDelta != 0) deltas.add(('Salvage', c.salvageDelta));
    if (c.loyaltyDelta != 0) deltas.add(('Loyalty', c.loyaltyDelta));
    if (c.resolveDelta != 0) deltas.add(('Resolve', c.resolveDelta));
    if (c.empathyDelta != 0) deltas.add(('Empathy', c.empathyDelta));
    if (c.authorityDelta != 0) deltas.add(('Authority', c.authorityDelta));
    if (c.reputationDelta != 0) deltas.add(('Accord Rep.', c.reputationDelta));
    if (c.civilianTensionDelta != 0) deltas.add(('Tension', c.civilianTensionDelta));
    if (c.orderDelta != 0) deltas.add(('Order', c.orderDelta));
    if (deltas.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: deltas.map((d) {
          final positive = d.$2 > 0;
          final isNegativeStat = d.$1 == 'Tension'; // tension going up = bad
          final isGood = positive != isNegativeStat;
          final color = isGood ? const Color(0xFF00FF88) : const Color(0xFFFF5555);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: color.withAlpha(120)),
              color: color.withAlpha(15),
            ),
            child: Text(
              '${d.$1}  ${positive ? "+" : ""}${d.$2}',
              style: TextStyle(fontSize: 9, letterSpacing: 1, color: color),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChoiceBtn extends StatefulWidget {
  final EncounterChoice choice;
  final VoidCallback onTap;
  const _ChoiceBtn({required this.choice, required this.onTap});

  @override
  State<_ChoiceBtn> createState() => _ChoiceBtnState();
}

class _ChoiceBtnState extends State<_ChoiceBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.choice.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _hovered ? c : c.withAlpha(80), width: _hovered ? 1.5 : 1),
            color: _hovered ? c.withAlpha(20) : Colors.transparent,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.choice.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c)),
            const SizedBox(height: 4),
            Text(widget.choice.sub,
                style: TextStyle(fontSize: 11, height: 1.4, color: Colors.white.withAlpha(120))),
          ]),
        ),
      ),
    );
  }
}

// ─── Game Over Dialog ─────────────────────────────────────────────────────────

class _GameOverDialog extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onMainMenu;
  const _GameOverDialog({required this.gameState, required this.onMainMenu});

  String get _endingTitle => switch (gameState.endingType) {
        'accord_hero' => 'ACCORD HERO',
        'roughneck_legend' => 'ROUGHNECK LEGEND',
        'the_truth' => 'THE TRUTH',
        _ => gameState.hull <= 0 ? 'SHIP LOST' : 'MISSION ENDED',
      };

  String get _endingBody => switch (gameState.endingType) {
        'accord_hero' =>
          'You followed every order. Completed every directive. '
          'The Civic Accord awarded you their highest commendation. '
          'Your crew attended the ceremony and applauded at the right moments. '
          'Nobody spoke about what they had seen. '
          'That was the deal.',
        'roughneck_legend' =>
          'You made enemies of the Accord and allies of your crew. '
          'The mission\'s outcome exceeded all projections. '
          'The official record will not mention your name. '
          'Your crew will not forget it.',
        'the_truth' =>
          'You know what the Accord knows and pretends not to. '
          'The Chithari are not mindless. The war is not what they told you. '
          'What you do with that knowledge is the only question that matters now.',
        _ => gameState.gameOverReason ?? 'The mission ended here.',
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF040814),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00FF88).withAlpha(120)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MISSION COMPLETE',
                style: TextStyle(fontSize: 9, letterSpacing: 4, color: Colors.white.withAlpha(120))),
            const SizedBox(height: 8),
            Text(_endingTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFF00FF88))),
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
            const SizedBox(height: 16),
            Text(_endingBody,
                style: const TextStyle(fontSize: 13, height: 1.75, color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onMainMenu();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00FF88)),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: const Text('RETURN TO TITLE',
                      style: TextStyle(letterSpacing: 3, color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI Components ─────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 10, color: const Color(0xFF00FF88)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9, letterSpacing: 3, color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _StatBar({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label.isNotEmpty)
          Row(children: [
            Text(label, style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white.withAlpha(140))),
            const Spacer(),
            Text('$value / $max', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(100))),
          ]),
        if (label.isNotEmpty) const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.white.withAlpha(20),
          color: color,
          minHeight: 4,
          borderRadius: BorderRadius.zero,
        ),
      ]),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double value;
  final Color color;
  const _MiniBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      backgroundColor: Colors.white.withAlpha(20),
      color: color,
      minHeight: 3,
      borderRadius: BorderRadius.zero,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(160)),
        color: color.withAlpha(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, letterSpacing: 1, color: color)),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _LabelRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: TextStyle(fontSize: 9, letterSpacing: 1, color: Colors.white.withAlpha(80))),
      const Spacer(),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: valueColor)),
      ),
    ]);
  }
}

class _CrewCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CrewCount(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.white.withAlpha(100))),
    ]);
  }
}

class _SectorDots extends StatelessWidget {
  final int current;
  const _SectorDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final done = i < current - 1;
        final active = i == current - 1;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: active ? 14 : 10,
            height: active ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? const Color(0xFF00FF88)
                  : active
                      ? const Color(0xFF00FF88).withAlpha(180)
                      : Colors.transparent,
              border: Border.all(
                color: (done || active) ? const Color(0xFF00FF88) : Colors.white.withAlpha(50),
                width: active ? 2 : 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionButton({required this.label, required this.color, required this.onPressed});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: _hovered ? widget.color : widget.color.withAlpha(160), width: 1.5),
            color: _hovered ? widget.color.withAlpha(25) : Colors.transparent,
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 4,
                    color: widget.color,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _PulsingButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _PulsingButton({required this.label, required this.onPressed});

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.fromRGBO(0, 255, 136, 0.4 + _pulse.value * 0.4),
              width: 1.5,
            ),
            color: Color.fromRGBO(0, 255, 136, 0.04 + _pulse.value * 0.04),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 255, 136, 0.08 + _pulse.value * 0.12),
                blurRadius: 12 + _pulse.value * 8,
              ),
            ],
          ),
          child: Center(
            child: Text(widget.label,
                style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 5,
                    color: Color(0xFF00FF88),
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
