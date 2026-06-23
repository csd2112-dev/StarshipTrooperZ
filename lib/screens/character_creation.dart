import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../widgets/starfield_painter.dart';
import 'galaxy_map_screen.dart';

// ─── Crew roster pool — player picks 4 from 8 if using custom mode ─────────

List<CrewMember> _rosterPool() => [
      CrewMember(name: 'Sgt. Varro', role: 'Combat Lead', status: CrewStatus.citizen, combatSkill: 75, loyalty: 65, fear: 15, hope: 60),
      CrewMember(name: 'Dr. Yessa', role: 'Field Medic', status: CrewStatus.civilian, medicalSkill: 80, diplomaticSkill: 50, loyalty: 55, fear: 25, hope: 80),
      CrewMember(name: 'Pvt. Drex', role: 'Engineer', status: CrewStatus.civilian, techSkill: 70, loyalty: 50, fear: 35, hope: 55),
      CrewMember(name: 'Cpl. Maren', role: 'Navigator', status: CrewStatus.citizen, techSkill: 55, diplomaticSkill: 45, loyalty: 70, fear: 20, hope: 70),
      CrewMember(name: 'Zhen', role: 'Xeno-Analyst', status: CrewStatus.civilian, alienKnowledge: 45, diplomaticSkill: 65, loyalty: 45, fear: 30, hope: 85),
      CrewMember(name: 'Lt. Cassara', role: 'Weapons Officer', status: CrewStatus.citizen, combatSkill: 65, techSkill: 50, loyalty: 75, fear: 10, hope: 65),
      CrewMember(name: 'Tomas', role: 'Salvage Specialist', status: CrewStatus.civilian, techSkill: 60, loyalty: 40, fear: 40, hope: 50),
      CrewMember(name: 'Orvaine', role: 'Diplomatic Envoy', status: CrewStatus.civilian, diplomaticSkill: 80, alienKnowledge: 40, loyalty: 50, fear: 20, hope: 90),
    ];

// ─── Screen ───────────────────────────────────────────────────────────────────

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationState();
}

class _CharacterCreationState extends State<CharacterCreationScreen>
    with TickerProviderStateMixin {
  // Steps: 0=Identity  1=Background  2=Port  3=Stats  4=Crew  5=Review
  int _step = 0;
  static const int _totalSteps = 6;

  // Step 0
  final _nameCtrl = TextEditingController();
  final _callsignCtrl = TextEditingController();

  // Step 1
  PlayerBackground? _background;

  // Step 2
  StartingPort? _port;

  // Step 3 — 12 bonus points to distribute
  int _bonusResolve = 0;
  int _bonusEmpathy = 0;
  int _bonusAuthority = 0;
  static const int _totalBonusPoints = 12;
  int get _usedPoints => _bonusResolve + _bonusEmpathy + _bonusAuthority;
  int get _remainingPoints => _totalBonusPoints - _usedPoints;

  // Step 4
  bool _randomCrew = true;
  final List<CrewMember> _roster = _rosterPool();
  final Set<int> _selectedCrew = {};
  static const int _requiredCrewCount = 4;

  // Animation
  late final AnimationController _starCtrl;
  late final List<StarData> _stars;

  @override
  void initState() {
    super.initState();
    _stars = generateStars(160, seed: 13);
    _starCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 90))
      ..repeat();
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _nameCtrl.dispose();
    _callsignCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty;
      case 1:
        return _background != null;
      case 2:
        return _port != null;
      case 3:
        return true; // bonus points are optional to spend
      case 4:
        return _randomCrew || _selectedCrew.length == _requiredCrewCount;
      case 5:
        return true;
      default:
        return false;
    }
  }

  void _advance() {
    if (!_canAdvance) return;
    if (_step == 5) {
      _deploy();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _deploy() {
    final state = GameState(
      commanderName: _nameCtrl.text.trim(),
      background: _background!,
      startingPort: _port!,
    );

    // Apply bonus points on top of background
    state.psychology.resolve =
        (state.psychology.resolve + _bonusResolve).clamp(0, 100);
    state.psychology.empathy =
        (state.psychology.empathy + _bonusEmpathy).clamp(0, 100);
    state.psychology.authority =
        (state.psychology.authority + _bonusAuthority).clamp(0, 100);

    // Apply callsign to log
    final callsign = _callsignCtrl.text.trim();
    if (callsign.isNotEmpty) {
      state.addLog('Callsign "${callsign.toUpperCase()}" registered with the Accord.');
    }

    // Override crew if custom
    if (!_randomCrew && _selectedCrew.isNotEmpty) {
      state.crew = _selectedCrew.map((i) => _roster[i]).toList();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => GalaxyMapScreen(gameState: state),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  // ─── Layout ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _buildHeader(),
                _buildProgressBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: _buildStep(),
                    ),
                  ),
                ),
                _buildNavRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const titles = [
      'COMMANDER IDENTITY',
      'SELECT BACKGROUND',
      'STARTING PORT',
      'COMMANDER PROFILE',
      'CREW SETUP',
      'MISSION BRIEFING',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF00FF88)),
              onPressed: _back,
            ),
          Expanded(
            child: Text(
              titles[_step],
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: 5,
                color: Color(0xFF00FF88),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '${_step + 1} / $_totalSteps',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Colors.white.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: done
                  ? const Color(0xFF00FF88)
                  : active
                      ? const Color(0xFF00FF88).withAlpha(180)
                      : Colors.white.withAlpha(30),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavRow() {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 0)
            _NavButton(label: '← BACK', onPressed: _back, primary: false)
          else
            const SizedBox(),
          _NavButton(
            label: isLast ? 'DEPLOY  ▶' : 'CONTINUE  →',
            onPressed: _canAdvance ? _advance : null,
            primary: true,
          ),
        ],
      ),
    );
  }

  // ─── Steps ───────────────────────────────────────────────────────────────────

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildIdentityStep();
      case 1:
        return _buildBackgroundStep();
      case 2:
        return _buildPortStep();
      case 3:
        return _buildStatsStep();
      case 4:
        return _buildCrewStep();
      case 5:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // Step 0 — Identity
  Widget _buildIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepSubtitle('Who are you, Commander? Your name and callsign will echo through AccordNet logs — and the after-action reports.'),
        const SizedBox(height: 28),
        _TerminalField(controller: _nameCtrl, label: 'FULL NAME', hint: 'e.g. Tessa Vorel', onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        _TerminalField(controller: _callsignCtrl, label: 'CALLSIGN (OPTIONAL)', hint: 'e.g. IRONVEIL'),
        const SizedBox(height: 32),
        _infoBox('Your identity is logged with the Civic Accord. Civilians and citizens will address you differently based on your background.'),
      ],
    );
  }

  // Step 1 — Background
  Widget _buildBackgroundStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepSubtitle('Your background determines your base psychological profile and starting loadout. Choose carefully — it shapes how crew and civilians respond to you from the first moment.'),
        const SizedBox(height: 20),
        ...PlayerBackground.values.map(
          (bg) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectCard(
              selected: _background == bg,
              onTap: () => setState(() => _background = bg),
              title: bg.displayName.toUpperCase(),
              subtitle: bg.description,
              tags: bg.statBonuses,
              tagColor: const Color(0xFF00FF88),
            ),
          ),
        ),
      ],
    );
  }

  // Step 2 — Port
  Widget _buildPortStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepSubtitle('Where does your mission begin? Your starting port determines your initial resources and the composition of your crew. There are no good options — only tradeoffs.'),
        const SizedBox(height: 20),
        ...StartingPort.values.map(
          (port) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectCard(
              selected: _port == port,
              onTap: () => setState(() => _port = port),
              title: port.displayName.toUpperCase(),
              subtitle: '${port.subtitle}\n\n${port.description}',
              tags: port.conditions,
              tagColor: const Color(0xFF00AAFF),
            ),
          ),
        ),
      ],
    );
  }

  // Step 3 — Stats customization
  Widget _buildStatsStep() {
    // Show background-adjusted base stats + bonus distribution
    final baseResolve = _background == null ? 50 : _baseResolve();
    final baseEmpathy = _background == null ? 50 : _baseEmpathy();
    final baseAuthority = _background == null ? 50 : _baseAuthority();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepSubtitle('You have $_totalBonusPoints bonus points to invest in your psychological profile. These compound with your background. Unused points are lost at deployment.'),
        const SizedBox(height: 8),
        _infoBox('Points remaining: $_remainingPoints / $_totalBonusPoints', color: _remainingPoints > 0 ? const Color(0xFF00FF88) : Colors.white.withAlpha(120)),
        const SizedBox(height: 24),
        _StatRow(
          label: 'RESOLVE',
          tooltip: 'Capacity to make hard decisions without breaking. Affects morale events and encounter outcomes.',
          base: baseResolve,
          bonus: _bonusResolve,
          canIncrease: _remainingPoints > 0 && _bonusResolve + baseResolve < 100,
          canDecrease: _bonusResolve > 0,
          onIncrease: () => setState(() => _bonusResolve++),
          onDecrease: () => setState(() => _bonusResolve--),
        ),
        const SizedBox(height: 12),
        _StatRow(
          label: 'EMPATHY',
          tooltip: 'How your crew bonds respond to your decisions. High empathy unlocks dialogue options and prevents morale collapse.',
          base: baseEmpathy,
          bonus: _bonusEmpathy,
          canIncrease: _remainingPoints > 0 && _bonusEmpathy + baseEmpathy < 100,
          canDecrease: _bonusEmpathy > 0,
          onIncrease: () => setState(() => _bonusEmpathy++),
          onDecrease: () => setState(() => _bonusEmpathy--),
        ),
        const SizedBox(height: 12),
        _StatRow(
          label: 'AUTHORITY',
          tooltip: 'Command presence. Civilians comply faster at high authority. Citizens expect it. Critical for maintaining order.',
          base: baseAuthority,
          bonus: _bonusAuthority,
          canIncrease: _remainingPoints > 0 && _bonusAuthority + baseAuthority < 100,
          canDecrease: _bonusAuthority > 0,
          onIncrease: () => setState(() => _bonusAuthority++),
          onDecrease: () => setState(() => _bonusAuthority--),
        ),
        const SizedBox(height: 24),
        _infoBox('HIDDEN STAT: Bug Sympathy — This evolves during play. Your background does not determine it. Your choices do.'),
      ],
    );
  }

  int _baseResolve() {
    int v = 50;
    if (_background == PlayerBackground.vanguardConscript) v += 20;
    if (_background == PlayerBackground.medtechSpecialist) v -= 5;
    return v.clamp(0, 100);
  }

  int _baseEmpathy() {
    int v = 50;
    if (_background == PlayerBackground.civicOfficer) v -= 10;
    if (_background == PlayerBackground.medtechSpecialist) v += 25;
    if (_background == PlayerBackground.xenodataAnalyst) v += 10;
    return v.clamp(0, 100);
  }

  int _baseAuthority() {
    int v = 50;
    if (_background == PlayerBackground.vanguardConscript) v += 10;
    if (_background == PlayerBackground.civicOfficer) v += 25;
    return v.clamp(0, 100);
  }

  // Step 4 — Crew
  Widget _buildCrewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepSubtitle('Assemble your crew. Every member carries their own psychology — loyalty, fear, trauma. Citizens expect hierarchy. Civilians resent it. How you manage both determines if you reach your destination.'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _CrewModeCard(
                label: 'RANDOM CREW',
                sub: 'The Accord assigns your crew. You get what you get.',
                selected: _randomCrew,
                onTap: () => setState(() {
                  _randomCrew = true;
                  _selectedCrew.clear();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CrewModeCard(
                label: 'CUSTOM CREW',
                sub: 'Choose $_requiredCrewCount from the available roster.',
                selected: !_randomCrew,
                onTap: () => setState(() => _randomCrew = false),
              ),
            ),
          ],
        ),
        if (!_randomCrew) ...[
          const SizedBox(height: 20),
          Text(
            'SELECT $_requiredCrewCount CREW MEMBERS   (${_selectedCrew.length}/$_requiredCrewCount)',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 3,
              color: _selectedCrew.length == _requiredCrewCount
                  ? const Color(0xFF00FF88)
                  : Colors.white.withAlpha(140),
            ),
          ),
          const SizedBox(height: 10),
          ..._roster.asMap().entries.map((e) {
            final i = e.key;
            final member = e.value;
            final selected = _selectedCrew.contains(i);
            final canSelect = selected || _selectedCrew.length < _requiredCrewCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CrewCard(
                member: member,
                selected: selected,
                enabled: canSelect,
                onTap: () => setState(() {
                  if (selected) {
                    _selectedCrew.remove(i);
                  } else if (_selectedCrew.length < _requiredCrewCount) {
                    _selectedCrew.add(i);
                  }
                }),
              ),
            );
          }),
        ],
      ],
    );
  }

  // Step 5 — Review
  Widget _buildReviewStep() {
    final callsign = _callsignCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepSubtitle('Final review before deployment. Once the mission initiates, your decisions are permanent.'),
        const SizedBox(height: 24),
        _ReviewSection(title: 'COMMANDER', rows: [
          ('Name', _nameCtrl.text.trim()),
          if (callsign.isNotEmpty) ('Callsign', callsign.toUpperCase()),
          ('Background', _background?.displayName ?? '—'),
          ('Starting Port', _port?.displayName ?? '—'),
        ]),
        const SizedBox(height: 12),
        _ReviewSection(title: 'PSYCHOLOGICAL PROFILE', rows: [
          ('Resolve', '${_baseResolve() + _bonusResolve}'),
          ('Empathy', '${_baseEmpathy() + _bonusEmpathy}'),
          ('Authority', '${_baseAuthority() + _bonusAuthority}'),
          ('Bug Sympathy', 'UNKNOWN — develops in the field'),
        ]),
        const SizedBox(height: 12),
        _ReviewSection(title: 'CREW', rows: [
          ('Mode', _randomCrew ? 'Accord-Assigned (Random)' : 'Custom Selection'),
          if (!_randomCrew)
            ..._selectedCrew.map((i) => (_roster[i].role, '${_roster[i].name} [${_roster[i].statusLabel}]')),
        ]),
        const SizedBox(height: 24),
        _infoBox('The Civic Accord does not guarantee safe passage. Your crew, your choices, your mission. Good luck, Commander.'),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _stepSubtitle(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: Colors.white.withAlpha(160),
        ),
      );

  Widget _infoBox(String text, {Color? color}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: (color ?? Colors.white).withAlpha(60)),
          color: Colors.white.withAlpha(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            height: 1.5,
            color: (color ?? Colors.white).withAlpha(180),
            letterSpacing: 0.5,
          ),
        ),
      );
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  const _NavButton({required this.label, required this.onPressed, required this.primary});

  @override
  Widget build(BuildContext context) {
    final accent = primary ? const Color(0xFF00FF88) : Colors.white;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null ? 0.3 : 1.0,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accent.withAlpha(180), width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: primary ? 28 : 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            color: accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TerminalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  const _TerminalField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, letterSpacing: 3, color: Color(0xFF00FF88)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withAlpha(60), fontSize: 14),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00FF88), width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00FF88), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final List<String> tags;
  final Color tagColor;
  const _SelectCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? tagColor : Colors.white.withAlpha(40),
            width: selected ? 1.5 : 1,
          ),
          color: selected ? tagColor.withAlpha(18) : Colors.white.withAlpha(5),
          boxShadow: selected
              ? [BoxShadow(color: tagColor.withAlpha(40), blurRadius: 12)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? tagColor : Colors.transparent,
                    border: Border.all(color: selected ? tagColor : Colors.white.withAlpha(80)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.white.withAlpha(180),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.white.withAlpha(140),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: tagColor.withAlpha(120)),
                          color: tagColor.withAlpha(15),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: tagColor,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String tooltip;
  final int base;
  final int bonus;
  final bool canIncrease;
  final bool canDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  const _StatRow({
    required this.label,
    required this.tooltip,
    required this.base,
    required this.bonus,
    required this.canIncrease,
    required this.canDecrease,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final total = (base + bonus).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 3, color: Color(0xFF00FF88))),
            const SizedBox(width: 8),
            Tooltip(
              message: tooltip,
              child: Icon(Icons.info_outline, size: 12, color: Colors.white.withAlpha(80)),
            ),
            const Spacer(),
            _AdjButton(icon: Icons.remove, onPressed: canDecrease ? onDecrease : null),
            const SizedBox(width: 12),
            SizedBox(
              width: 32,
              child: Text(
                '$total',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            _AdjButton(icon: Icons.add, onPressed: canIncrease ? onIncrease : null),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 3, color: Colors.white.withAlpha(20)),
            FractionallySizedBox(
              widthFactor: base / 100,
              child: Container(height: 3, color: Colors.white.withAlpha(60)),
            ),
            FractionallySizedBox(
              widthFactor: total / 100,
              child: Container(height: 3, color: const Color(0xFF00FF88)),
            ),
          ],
        ),
        if (bonus > 0)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              'Base $base  +$bonus bonus',
              style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(80), letterSpacing: 1),
            ),
          ),
      ],
    );
  }
}

class _AdjButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _AdjButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onPressed == null ? 0.25 : 1.0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00FF88).withAlpha(150)),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF00FF88)),
        ),
      ),
    );
  }
}

class _CrewModeCard extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _CrewModeCard({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFF00FF88) : Colors.white.withAlpha(40),
            width: selected ? 1.5 : 1,
          ),
          color: selected ? const Color(0xFF00FF88).withAlpha(18) : Colors.white.withAlpha(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.white.withAlpha(160),
                )),
            const SizedBox(height: 8),
            Text(sub,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Colors.white.withAlpha(120),
                )),
          ],
        ),
      ),
    );
  }
}

class _CrewCard extends StatelessWidget {
  final CrewMember member;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _CrewCard({
    required this.member,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  String get _topSkill {
    final skills = {
      'Combat': member.combatSkill,
      'Tech': member.techSkill,
      'Medical': member.medicalSkill,
      'Diplomatic': member.diplomaticSkill,
      'Xeno': member.alienKnowledge,
    };
    final top = skills.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${top.key} ${top.value}';
  }

  @override
  Widget build(BuildContext context) {
    final isC = member.status == CrewStatus.citizen;
    final statusColor = isC ? const Color(0xFF00AAFF) : const Color(0xFFFFAA00);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? const Color(0xFF00FF88) : Colors.white.withAlpha(30),
              width: selected ? 1.5 : 1,
            ),
            color: selected ? const Color(0xFF00FF88).withAlpha(12) : Colors.transparent,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFF00FF88) : Colors.transparent,
                  border: Border.all(
                    color: selected ? const Color(0xFF00FF88) : Colors.white.withAlpha(60),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(member.role,
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(120))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: statusColor.withAlpha(160)),
                      color: statusColor.withAlpha(20),
                    ),
                    child: Text(
                      member.statusLabel,
                      style: TextStyle(fontSize: 9, letterSpacing: 1, color: statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _topSkill,
                    style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(100)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _ReviewSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withAlpha(40)),
        color: Colors.white.withAlpha(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10, letterSpacing: 4, color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(r.$1.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10, letterSpacing: 1, color: Colors.white.withAlpha(100))),
                    ),
                    Expanded(
                      child: Text(r.$2,
                          style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
