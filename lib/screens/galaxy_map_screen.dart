import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/encounter.dart';
import '../models/star_system.dart';
import '../engine/encounter_engine.dart';
import '../widgets/starfield_painter.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/shop_dialog.dart';
import 'title_screen.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class GalaxyMapScreen extends StatefulWidget {
  final GameState gameState;
  const GalaxyMapScreen({super.key, required this.gameState});

  @override
  State<GalaxyMapScreen> createState() => _GalaxyMapScreenState();
}

class _GalaxyMapScreenState extends State<GalaxyMapScreen>
    with TickerProviderStateMixin {
  // Starfield
  late AnimationController _starCtrl;
  late List<StarData> _stars;

  // Map animation
  late AnimationController _shipCtrl;
  late AnimationController _pulseCtrl;
  Offset _shipFrom = kGalaxySystems.first.position;
  Offset _shipTo = kGalaxySystems.first.position;
  StarSystem? _pendingDest;
  bool _isMoving = false;
  Size _mapSize = Size.zero;

  // Map state
  String _currentSystemId = 'vektara';
  final Set<String> _visitedIds = {'vektara'};
  final Set<String> _seenNpcIds = {};

  // Dialogue
  List<DialogueLine>? _activeDialogue;
  VoidCallback? _afterDialogue;

  // Encounter engine
  late GameState _gs;
  final Set<String> _playedIds = {};

  // UI
  bool _isPaused = false;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _gs = widget.gameState;

    _stars = generateStars(120, seed: 99);
    _starCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 70))
          ..repeat();

    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _shipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _shipCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && _pendingDest != null) {
        final dest = _pendingDest!;
        _pendingDest = null;
        _onArrival(dest);
      }
    });

    // Show starting NPC dialogue after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryShowDialogue('vektara', then: null);
    });
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _pulseCtrl.dispose();
    _shipCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  Offset get _shipNormPos =>
      Offset.lerp(_shipFrom, _shipTo, _shipCtrl.value)!;

  void _handleMapTap(Offset localPos) {
    if (_isMoving || _activeDialogue != null || _mapSize == Size.zero) return;
    final current =
        kGalaxySystems.firstWhere((s) => s.id == _currentSystemId);
    for (final sys in kGalaxySystems) {
      final nodePixel = sys.pixelPos(_mapSize);
      if ((localPos - nodePixel).distance < 28) {
        if (sys.id != _currentSystemId &&
            current.connections.contains(sys.id) &&
            !_gs.isConnectionBlocked(_currentSystemId, sys.id)) {
          _navigateTo(sys);
        }
        return;
      }
    }
  }

  void _navigateTo(StarSystem dest) {
    final current =
        kGalaxySystems.firstWhere((s) => s.id == _currentSystemId);
    _shipFrom = current.position;
    _shipTo = dest.position;
    _pendingDest = dest;
    setState(() => _isMoving = true);
    _shipCtrl.forward(from: 0);
  }

  void _onArrival(StarSystem dest) {
    // Per-jump running costs (fuel, O2, rations)
    EncounterEngine.applyJumpCost(_gs);

    setState(() {
      _currentSystemId = dest.id;
      _visitedIds.add(dest.id);
      _isMoving = false;
    });

    if (_gs.isGameOver) {
      _showGameOver();
      return;
    }

    // Sector advance when entering a deeper region
    while (dest.sector > _gs.sector) {
      EncounterEngine.advanceSector(_gs);
      if (_gs.isGameOver) {
        setState(() {});
        _showGameOver();
        return;
      }
    }

    _tryShowDialogue(dest.id, then: _checkForEncounter);
  }

  void _openShop() {
    showDialog(
      context: context,
      builder: (_) => ShopDialog(
        gameState: _gs,
        onPurchase: () => setState(() {}),
      ),
    );
  }

  void _tryShowDialogue(String systemId, {VoidCallback? then}) {
    final lines = kSystemDialogue[systemId];
    if (lines == null || lines.isEmpty || _seenNpcIds.contains(systemId)) {
      then?.call();
      return;
    }
    _seenNpcIds.add(systemId);
    setState(() {
      _activeDialogue = lines
          .map((l) => DialogueLine(
                speakerName: l['speaker']!,
                speakerRole: l['role']!,
                portrait: _parsePortrait(l['portrait']!),
                text: l['text']!,
              ))
          .toList();
      _afterDialogue = then;
    });
  }

  void _checkForEncounter() {
    if (!mounted) return;
    final encounter = EncounterEngine.pick(_gs, _playedIds);
    if (encounter == null) return;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _triggerEncounter(encounter);
    });
  }

  void _triggerEncounter(EncounterData encounter) {
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
          });
          if (_gs.isGameOver) _showGameOver();
        },
      ),
    );
  }

  void _completeMission() {
    EncounterEngine.advanceSector(_gs);
    setState(() {});
    _showGameOver();
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

  PortraitType _parsePortrait(String s) => switch (s) {
        'official' => PortraitType.accordOfficial,
        'commander' => PortraitType.commander,
        'trader' => PortraitType.trader,
        'alien' => PortraitType.alien,
        _ => PortraitType.crewMember,
      };

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (e) {
        if (e is KeyDownEvent &&
            e.logicalKey == LogicalKeyboardKey.escape) {
          setState(() => _isPaused = !_isPaused);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Starfield background
            AnimatedBuilder(
              animation: _starCtrl,
              builder: (_, __) => CustomPaint(
                painter:
                    StarfieldPainter(stars: _stars, offset: _starCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: LayoutBuilder(builder: (ctx, c) {
                      return c.maxWidth > 820
                          ? _buildWideLayout()
                          : _buildNarrowLayout();
                    }),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
            if (_isPaused)
              _PauseOverlay(
                onResume: () => setState(() => _isPaused = false),
                onNewGame: _goToTitle,
              ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        border: Border(
            bottom: BorderSide(color: const Color(0xFF00FF88).withAlpha(70))),
      ),
      child: Row(
        children: [
          _SectorDots(current: _gs.sector),
          const SizedBox(width: 12),
          Text('SECTOR ${_gs.sector} / 5',
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  color: Color(0xFF00FF88))),
          const Spacer(),
          // Credits display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFFFFDD44).withAlpha(100)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('₢ ',
                  style: TextStyle(fontSize: 9, color: Color(0xFFFFDD44))),
              Text('${_gs.credits}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFDD44))),
            ]),
          ),
          const SizedBox(width: 10),
          // Revolt warning
          if (_gs.civilianTension >= 70)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                _gs.civilianTension >= 90 ? '⚠ REVOLT IMMINENT' : '⚠ REVOLT RISK',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: _gs.civilianTension >= 90
                        ? const Color(0xFFFF4444)
                        : const Color(0xFFFFAA00),
                    fontWeight: FontWeight.bold),
              ),
            ),
          Text('DAY ${_gs.day}',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: Colors.white.withAlpha(140))),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CMD. ${_gs.commanderName.toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
              Text(_gs.background.displayName.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: Colors.white.withAlpha(100))),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _isPaused = !_isPaused),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withAlpha(60))),
              child: Icon(Icons.menu,
                  size: 16, color: Colors.white.withAlpha(160)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Layouts ────────────────────────────────────────────────────────────────

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar
        SizedBox(
          width: 220,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              _buildShipPanel(),
              const SizedBox(height: 8),
              _buildOrderPanel(),
              const SizedBox(height: 8),
              _buildPsychPanel(),
              const SizedBox(height: 8),
              _buildUpgradesPanel(),
            ]),
          ),
        ),
        // Center: galaxy map
        Expanded(child: _buildMapArea()),
        // Right sidebar
        SizedBox(
          width: 200,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              _buildCrewPanel(),
              const SizedBox(height: 8),
              _buildAlienPanel(),
              const SizedBox(height: 8),
              _buildLogPanel(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(children: [
        SizedBox(height: 340, child: _buildMapArea()),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            _buildShipPanel(),
            const SizedBox(height: 8),
            _buildOrderPanel(),
            const SizedBox(height: 8),
            _buildCrewPanel(),
            const SizedBox(height: 8),
            _buildPsychPanel(),
            const SizedBox(height: 8),
            _buildLogPanel(),
          ]),
        ),
      ]),
    );
  }

  // ─── Galaxy Map Area ────────────────────────────────────────────────────────

  Widget _buildMapArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Subtle map grid overlay
        CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
        // Galaxy map canvas
        LayoutBuilder(builder: (ctx, constraints) {
          final size = constraints.biggest;
          _mapSize = size;
          return GestureDetector(
            onTapUp: (d) => _handleMapTap(d.localPosition),
            child: AnimatedBuilder(
              animation: Listenable.merge([_shipCtrl, _pulseCtrl]),
              builder: (_, __) => CustomPaint(
                size: size,
                painter: GalaxyMapPainter(
                  systems: kGalaxySystems,
                  currentSystemId: _currentSystemId,
                  visitedIds: _visitedIds,
                  blockedConnections: _gs.blockedConnections,
                  shipNormPos: _shipNormPos,
                  pulseValue: _pulseCtrl.value,
                ),
              ),
            ),
          );
        }),
        // Dialogue overlay at bottom of map
        if (_activeDialogue != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DialogueBox(
              key: ValueKey(_activeDialogue.hashCode),
              lines: _activeDialogue!,
              onComplete: () {
                final cb = _afterDialogue;
                setState(() {
                  _activeDialogue = null;
                  _afterDialogue = null;
                });
                cb?.call();
              },
            ),
          ),
      ],
    );
  }

  // ─── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final current =
        kGalaxySystems.firstWhere((s) => s.id == _currentSystemId);
    final atFinal = _currentSystemId == 'accordprime' && !_gs.isGameOver;
    final atShop = current.isShop &&
        !_isMoving &&
        !_gs.isGameOver &&
        _activeDialogue == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        border: Border(
            top: BorderSide(color: const Color(0xFF00FF88).withAlpha(40))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CURRENT POSITION',
                  style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 2,
                      color: Colors.white.withAlpha(70))),
              const SizedBox(height: 2),
              Text(current.name.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 3,
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.bold)),
              Text(current.subtitle,
                  style: TextStyle(
                      fontSize: 9, color: Colors.white.withAlpha(90))),
            ],
          ),
          const Spacer(),
          if (atShop)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ActionBtn(
                label: '⊕  TRADE POST',
                color: const Color(0xFF00DDCC),
                onPressed: _openShop,
              ),
            ),
          if (_gs.isGameOver)
            _ActionBtn(
              label: '◉  VIEW ENDING',
              color: const Color(0xFFFFDD44),
              onPressed: _showGameOver,
            )
          else if (atFinal)
            _ActionBtn(
              label: '◉  COMPLETE MISSION',
              color: const Color(0xFFCC88FF),
              onPressed: _completeMission,
            )
          else if (_isMoving)
            Text('NAVIGATING...',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    color: Colors.white.withAlpha(80)))
          else
            Text('SELECT A CONNECTED SYSTEM TO NAVIGATE',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: Colors.white.withAlpha(50))),
        ],
      ),
    );
  }

  // ─── HUD Panels ─────────────────────────────────────────────────────────────

  Widget _buildShipPanel() {
    return _Panel(
      title: 'SHIP STATUS',
      child: Column(children: [
        _StatBar(
            label: 'HULL',
            value: _gs.hull,
            max: _gs.maxHull,
            color: _healthColor(_gs.hull, _gs.maxHull)),
        _StatBar(
            label: 'FUEL',
            value: _gs.fuel,
            max: _gs.maxFuel,
            color: const Color(0xFF00AAFF)),
        _StatBar(
            label: 'O2',
            value: _gs.oxygen,
            max: _gs.maxOxygen,
            color: _healthColor(_gs.oxygen, _gs.maxOxygen)),
        _StatBar(
            label: 'RATIONS',
            value: _gs.rations,
            max: _gs.maxRations,
            color: const Color(0xFFFFAA00)),
        _StatBar(
            label: 'AMMO',
            value: _gs.ammo,
            max: 100,
            color: const Color(0xFFCC88FF)),
        _StatBar(
            label: 'MED',
            value: _gs.medicine,
            max: 100,
            color: const Color(0xFF00DDCC)),
        const SizedBox(height: 4),
        Row(children: [
          Text('SALVAGE',
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: Colors.white.withAlpha(140))),
          const Spacer(),
          Text('${_gs.salvage}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFDD44))),
          Text('  u',
              style:
                  TextStyle(fontSize: 9, color: Colors.white.withAlpha(80))),
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
        _StatBar(
            label: 'ORDER',
            value: _gs.orderLevel,
            max: 100,
            color: const Color(0xFF00FF88)),
        const SizedBox(height: 6),
        Row(children: [
          Text('CIV TENSION',
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1,
                  color: Colors.white.withAlpha(140))),
          const Spacer(),
          _Badge(label: _gs.tensionLabel, color: tColor),
        ]),
        const SizedBox(height: 5),
        _StatBar(label: '', value: _gs.civilianTension, max: 100, color: tColor),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _CrewCount('CIT.', _gs.citizenCount, const Color(0xFF00AAFF)),
          Container(
              width: 1, height: 24, color: Colors.white.withAlpha(30)),
          _CrewCount('CIV.', _gs.civilianCount, const Color(0xFFFFAA00)),
          Container(
              width: 1, height: 24, color: Colors.white.withAlpha(30)),
          _CrewCount('ALIVE', _gs.aliveCount, Colors.white),
        ]),
      ]),
    );
  }

  Widget _buildPsychPanel() {
    return _Panel(
      title: 'CMD PSYCH',
      child: Column(children: [
        _StatBar(
            label: 'RESOLVE',
            value: _gs.psychology.resolve,
            max: 100,
            color: const Color(0xFF00FF88)),
        _StatBar(
            label: 'EMPATHY',
            value: _gs.psychology.empathy,
            max: 100,
            color: const Color(0xFF00AAFF)),
        _StatBar(
            label: 'AUTH.',
            value: _gs.psychology.authority,
            max: 100,
            color: const Color(0xFFCC88FF)),
        const SizedBox(height: 6),
        _LabelRow(
            'ACCORD', _gs.psychology.reputationLabel,
            _gs.psychology.reputation >= 0
                ? const Color(0xFF00AAFF)
                : const Color(0xFFFF4444)),
      ]),
    );
  }

  Widget _buildUpgradesPanel() {
    final keys = ['hull', 'drive', 'med', 'quarters', 'weapons', 'research'];
    final names = [
      'Hull Plating', 'Drive Core', 'Med Bay',
      'Quarters', 'Weapons', 'Research'
    ];
    return _Panel(
      title: 'UPGRADES  •  10 sal',
      child: Column(
        children: List.generate(6, (i) {
          final lvl = _gs.upgrades.levelOf(i);
          final canBuy = _gs.salvage >= 10 && lvl < 3;
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Expanded(
                  child:
                      Text(names[i], style: const TextStyle(fontSize: 10))),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    3,
                    (j) => Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: j < lvl
                                  ? const Color(0xFF00FF88)
                                  : Colors.transparent,
                              border: Border.all(
                                color: j < lvl
                                    ? const Color(0xFF00FF88)
                                    : Colors.white.withAlpha(40),
                              ),
                            ),
                          ),
                        )),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: canBuy
                    ? () {
                        final ok = _gs.purchaseUpgrade(keys[i]);
                        if (ok) {
                          setState(() =>
                              _gs.addLog('${names[i]} upgraded.'));
                        }
                      }
                    : null,
                child: Opacity(
                  opacity: canBuy ? 1.0 : 0.25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFFFDD44).withAlpha(160))),
                    child: const Text('BUY',
                        style: TextStyle(
                            fontSize: 7,
                            letterSpacing: 1,
                            color: Color(0xFFFFDD44))),
                  ),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _buildCrewPanel() {
    final alive = _gs.crew.where((c) => c.isAlive).toList();
    return _Panel(
      title: 'CREW MANIFEST',
      child: Column(
        children: alive.map((c) {
          final isCitizen = c.status == CrewStatus.citizen;
          final sColor = isCitizen
              ? const Color(0xFF00AAFF)
              : const Color(0xFFFFAA00);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            Text(c.role,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white.withAlpha(120))),
                          ]),
                    ),
                    _Badge(label: c.statusLabel, color: sColor),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                        child: _MiniBar(
                            value: c.loyalty / 100,
                            color: const Color(0xFF00FF88))),
                    const SizedBox(width: 6),
                    Text(c.loyaltyLabel,
                        style: TextStyle(
                            fontSize: 8,
                            color: Colors.white.withAlpha(120))),
                  ]),
                ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlienPanel() {
    return _Panel(
      title: 'ALIEN DB',
      child: Column(
        children: AlienSpecies.values.map((s) {
          final k = _gs.alienKnowledge[s] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(s.displayName,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('$k%',
                        style: TextStyle(
                            fontSize: 9, color: Colors.white.withAlpha(120))),
                  ]),
                  const SizedBox(height: 2),
                  _MiniBar(
                      value: k / 100,
                      color: const Color(0xFFCC88FF)),
                ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogPanel() {
    return _Panel(
      title: 'MISSION LOG',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _gs.missionLog.take(10).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('> $e',
                  style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: Colors.white.withAlpha(160))),
            )).toList(),
      ),
    );
  }
}

// ─── Galaxy Map Painter ───────────────────────────────────────────────────────

class GalaxyMapPainter extends CustomPainter {
  final List<StarSystem> systems;
  final String currentSystemId;
  final Set<String> visitedIds;
  final Set<String> blockedConnections;
  final Offset shipNormPos;
  final double pulseValue;

  const GalaxyMapPainter({
    required this.systems,
    required this.currentSystemId,
    required this.visitedIds,
    required this.blockedConnections,
    required this.shipNormPos,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnections(canvas, size);

    final current = systems.firstWhere((s) => s.id == currentSystemId);
    final reachable = current.connections.toSet();

    for (final sys in systems) {
      _drawNode(canvas, sys, size, reachable);
    }

    final shipPixel =
        Offset(shipNormPos.dx * size.width, shipNormPos.dy * size.height);
    _drawShip(canvas, shipPixel);
  }

  void _drawConnections(Canvas canvas, Size size) {
    final normalPaint = Paint()
      ..color = Colors.white.withAlpha(22)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final blockedPaint = Paint()
      ..color = const Color(0xFFFF4444).withAlpha(110)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final drawn = <String>{};
    for (final sys in systems) {
      for (final connId in sys.connections) {
        final key = ([sys.id, connId]..sort()).join('-');
        if (drawn.contains(key)) continue;
        drawn.add(key);
        final conn =
            systems.firstWhere((s) => s.id == connId, orElse: () => sys);
        final from = sys.pixelPos(size);
        final to = conn.pixelPos(size);

        if (blockedConnections.contains(key)) {
          _drawDashed(canvas, from, to, blockedPaint);
        } else {
          canvas.drawLine(from, to, normalPaint);
        }
      }
    }
  }

  void _drawDashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dir = to - from;
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;
    const dash = 6.0;
    const gap = 4.0;
    double pos = 0;
    while (pos < len) {
      final a = from + unit * pos;
      final b = from + unit * (pos + dash).clamp(0.0, len);
      canvas.drawLine(a, b, paint);
      pos += dash + gap;
    }
  }

  void _drawNode(
      Canvas canvas, StarSystem sys, Size size, Set<String> reachable) {
    final pos = sys.pixelPos(size);
    final isCurrent = sys.id == currentSystemId;
    final isReachable = reachable.contains(sys.id);
    final isVisited = visitedIds.contains(sys.id);
    final isFinal = sys.id == 'accordprime';
    final color = isFinal ? const Color(0xFFCC88FF) : _typeColor(sys.type);

    // Shop ring
    if (sys.isShop) {
      canvas.drawCircle(
        pos,
        14,
        Paint()
          ..color = const Color(0xFF00DDCC).withAlpha(isCurrent ? 80 : 40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Pulse ring on reachable systems
    if (isReachable) {
      canvas.drawCircle(
        pos,
        22 + pulseValue * 5,
        Paint()
          ..color = color.withAlpha((45 + pulseValue * 55).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Glow on current system
    if (isCurrent) {
      canvas.drawCircle(
        pos,
        16,
        Paint()
          ..color = color.withAlpha(50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    final radius = isCurrent ? 10.0 : 8.0;
    final fillColor = isCurrent
        ? color
        : isVisited
            ? color.withAlpha(160)
            : color.withAlpha(70);

    canvas.drawCircle(pos, radius,
        Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = isCurrent ? Colors.white : color.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 2 : 1,
    );

    // Name label
    _paintText(
      canvas,
      pos.translate(0, 16),
      sys.name.toUpperCase(),
      size: 8.5,
      color: isCurrent
          ? Colors.white
          : isReachable
              ? color
              : Colors.white.withAlpha(80),
      bold: isCurrent,
    );

    // Sector hint for reachable/current
    if (isCurrent || isReachable) {
      _paintText(
        canvas,
        pos.translate(0, 27),
        'SECTOR ${sys.sector}',
        size: 7,
        color: Colors.white.withAlpha(60),
      );
    }

    // Shop label
    if (sys.isShop && (isCurrent || isReachable)) {
      _paintText(
        canvas,
        pos.translate(0, 36),
        '[ TRADE ]',
        size: 7,
        color: const Color(0xFF00DDCC).withAlpha(180),
      );
    }

    // NPC dot (unvisited systems with NPCs)
    if (sys.hasNpc && !isVisited) {
      canvas.drawCircle(
        pos.translate(13, -13),
        4,
        Paint()..color = const Color(0xFFFFDD44),
      );
    }
  }

  void _drawShip(Canvas canvas, Offset pos) {
    const color = Color(0xFF00FF88);

    // Engine glow
    canvas.drawCircle(
      pos,
      12,
      Paint()
        ..color = color.withAlpha(35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Ship chevron
    final path = Path()
      ..moveTo(pos.dx, pos.dy - 9)
      ..lineTo(pos.dx + 5, pos.dy + 5)
      ..lineTo(pos.dx, pos.dy + 2)
      ..lineTo(pos.dx - 5, pos.dy + 5)
      ..close();

    canvas.drawPath(path,
        Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _paintText(Canvas canvas, Offset center, String text,
      {required double size, required Color color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: size,
              color: color,
              letterSpacing: 1,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, 0));
  }

  Color _typeColor(StarSystemType type) => switch (type) {
        StarSystemType.station => const Color(0xFF00AAFF),
        StarSystemType.planet => const Color(0xFF00FF88),
        StarSystemType.debris => const Color(0xFFFFAA00),
        StarSystemType.jumpgate => const Color(0xFFCC88FF),
      };

  @override
  bool shouldRepaint(GalaxyMapPainter old) =>
      old.shipNormPos != shipNormPos ||
      old.pulseValue != pulseValue ||
      old.currentSystemId != currentSystemId ||
      old.visitedIds != visitedIds ||
      old.blockedConnections.length != blockedConnections.length;
}

// ─── Subtle map grid ─────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(6)
      ..strokeWidth = 0.5;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─── Pause Overlay ────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onNewGame;
  const _PauseOverlay({required this.onResume, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResume,
      child: Container(
        color: Colors.black.withAlpha(200),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF040814),
              border: Border.all(
                  color: const Color(0xFF00FF88).withAlpha(160), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00FF88).withAlpha(30),
                    blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('MISSION PAUSED',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 6,
                        color: Color(0xFF00FF88),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                    height: 1,
                    color: const Color(0xFF00FF88).withAlpha(60)),
                const SizedBox(height: 28),
                _MenuBtn(
                    label: 'RESUME MISSION',
                    color: const Color(0xFF00FF88),
                    onTap: onResume),
                const SizedBox(height: 12),
                _MenuBtn(
                    label: 'EXIT TO TITLE',
                    color: Colors.white.withAlpha(160),
                    onTap: onNewGame),
                const SizedBox(height: 20),
                Text('ESC to close',
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 2,
                        color: Colors.white.withAlpha(60))),
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
  const _MenuBtn(
      {required this.label, required this.color, required this.onTap});

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
            border: Border.all(
                color: _hovered
                    ? widget.color
                    : widget.color.withAlpha(80)),
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
  const _EncounterDialog(
      {required this.encounter,
      required this.gameState,
      required this.onResolved});

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
            border:
                Border.all(color: const Color(0xFF00FF88).withAlpha(120))),
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
              style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 4,
                  color: Color(0xFF00FF88))),
          const SizedBox(height: 6),
          Text(widget.encounter.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
          const SizedBox(height: 16),
          Text(widget.encounter.story,
              style:
                  const TextStyle(fontSize: 13, height: 1.75, color: Colors.white)),
          const SizedBox(height: 24),
          ...widget.encounter.choices.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceBtn(
                    choice: c,
                    onTap: () => setState(() => _chosen = c)),
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
              style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 4,
                  color: Color(0xFF00FF88))),
          const SizedBox(height: 6),
          const Text('OUTCOME',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
          const SizedBox(height: 16),
          Text(_chosen!.outcome,
              style:
                  const TextStyle(fontSize: 13, height: 1.75, color: Colors.white)),
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
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
              child: const Text('CONTINUE  →',
                  style: TextStyle(
                      letterSpacing: 3,
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.bold)),
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
    if (c.civilianTensionDelta != 0) {
      deltas.add(('Tension', c.civilianTensionDelta));
    }
    if (c.orderDelta != 0) deltas.add(('Order', c.orderDelta));
    if (deltas.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: deltas.map((d) {
          final positive = d.$2 > 0;
          final isNeg = d.$1 == 'Tension';
          final isGood = positive != isNeg;
          final color =
              isGood ? const Color(0xFF00FF88) : const Color(0xFFFF5555);
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: color.withAlpha(120)),
              color: color.withAlpha(15),
            ),
            child: Text(
              '${d.$1}  ${positive ? "+" : ""}${d.$2}',
              style:
                  TextStyle(fontSize: 9, letterSpacing: 1, color: color),
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
            border: Border.all(
                color: _hovered ? c : c.withAlpha(80),
                width: _hovered ? 1.5 : 1),
            color: _hovered ? c.withAlpha(20) : Colors.transparent,
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.choice.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: c)),
                const SizedBox(height: 4),
                Text(widget.choice.sub,
                    style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.white.withAlpha(120))),
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
  const _GameOverDialog(
      {required this.gameState, required this.onMainMenu});

  String get _title => switch (gameState.endingType) {
        'accord_hero' => 'ACCORD HERO',
        'roughneck_legend' => 'ROUGHNECK LEGEND',
        'the_truth' => 'THE TRUTH',
        _ => gameState.hull <= 0 ? 'SHIP LOST' : 'MISSION ENDED',
      };

  String get _body => switch (gameState.endingType) {
        'accord_hero' =>
          'You followed every order. Completed every directive. The Civic Accord awarded you their highest commendation. Nobody spoke about what they had seen. That was the deal.',
        'roughneck_legend' =>
          'You made enemies of the Accord and allies of your crew. The mission\'s outcome exceeded all projections. The official record will not mention your name. Your crew will not forget it.',
        'the_truth' =>
          'You know what the Accord knows and pretends not to. The Chithari are not mindless. The war is not what they told you. What you do with that knowledge is the only question that matters now.',
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
            border:
                Border.all(color: const Color(0xFF00FF88).withAlpha(120))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MISSION COMPLETE',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 4,
                    color: Colors.white.withAlpha(120))),
            const SizedBox(height: 8),
            Text(_title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Color(0xFF00FF88))),
            const SizedBox(height: 16),
            Container(
                height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
            const SizedBox(height: 16),
            Text(_body,
                style: const TextStyle(
                    fontSize: 13, height: 1.75, color: Colors.white)),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onMainMenu();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00FF88)),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                child: const Text('RETURN TO TITLE',
                    style: TextStyle(
                        letterSpacing: 3,
                        color: Color(0xFF00FF88),
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI Widgets ────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 9, color: const Color(0xFF00FF88)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 8,
                    letterSpacing: 3,
                    color: Color(0xFF00FF88),
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 10),
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
  const _StatBar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label.isNotEmpty)
          Row(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: Colors.white.withAlpha(140))),
            const Spacer(),
            Text('$value',
                style: TextStyle(
                    fontSize: 9, color: Colors.white.withAlpha(100))),
          ]),
        if (label.isNotEmpty) const SizedBox(height: 3),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.white.withAlpha(20),
          color: color,
          minHeight: 3,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(160)),
        color: color.withAlpha(20),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 8, letterSpacing: 1, color: color)),
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
      Text(label,
          style: TextStyle(
              fontSize: 8,
              letterSpacing: 1,
              color: Colors.white.withAlpha(80))),
      const Spacer(),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: valueColor)),
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
      Text('$count',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color)),
      Text(label,
          style: TextStyle(
              fontSize: 7,
              letterSpacing: 1,
              color: Colors.white.withAlpha(100))),
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
            width: active ? 13 : 9,
            height: active ? 13 : 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? const Color(0xFF00FF88)
                  : active
                      ? const Color(0xFF00FF88).withAlpha(180)
                      : Colors.transparent,
              border: Border.all(
                color: (done || active)
                    ? const Color(0xFF00FF88)
                    : Colors.white.withAlpha(50),
                width: active ? 2 : 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionBtn(
      {required this.label, required this.color, required this.onPressed});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
                color: _hovered
                    ? widget.color
                    : widget.color.withAlpha(160),
                width: 1.5),
            color:
                _hovered ? widget.color.withAlpha(25) : Colors.transparent,
          ),
          child: Text(widget.label,
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 3,
                  color: widget.color,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
