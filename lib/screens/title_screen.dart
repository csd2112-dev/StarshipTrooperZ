import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/starfield_painter.dart';
import '../widgets/codex_dialog.dart';
import 'character_creation.dart';

// ─── Title Screen ─────────────────────────────────────────────────────────────

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with TickerProviderStateMixin {
  late final AnimationController _starController;
  late final AnimationController _glowController;
  late final AnimationController _introController;
  late final AnimationController _uiFadeController;
  late final FocusNode _focusNode;
  late final List<StarData> _stars;
  bool _introDone = false;

  late final Animation<double> _logoY;
  late final Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _stars = generateStars(180, seed: 7);
    _focusNode = FocusNode();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _uiFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoY = Tween<double>(begin: -280.0, end: 0.0)
        .animate(CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutBack,
    ));

    _logoFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.6),
    ));

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onIntroDone();
    });

    _introController.forward();
  }

  void _skipIntro() {
    if (_introDone) return;
    _introController.stop();
    _introController.value = 1.0;
    _onIntroDone();
  }

  void _onIntroDone() {
    if (!mounted || _introDone) return;
    setState(() => _introDone = true);
    _uiFadeController.forward();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _starController.dispose();
    _glowController.dispose();
    _introController.dispose();
    _uiFadeController.dispose();
    super.dispose();
  }

  void _startMission() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const CharacterCreationScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }

  void _showLoreDialog() {
    showDialog(context: context, builder: (_) => const _LoreDialog());
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (e) {
        if (e is KeyDownEvent) _skipIntro();
      },
      child: GestureDetector(
        onTap: _introDone ? null : _skipIntro,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Starfield ──────────────────────────────────────────────
              AnimatedBuilder(
                animation: _starController,
                builder: (_, __) => CustomPaint(
                  painter: StarfieldPainter(
                    stars: _stars,
                    offset: _starController.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),

              // ── CRT Scanlines ──────────────────────────────────────────
              const CustomPaint(
                painter: _ScanlinePainter(),
                child: SizedBox.expand(),
              ),

              // ── Main content ───────────────────────────────────────────
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo — drops in on load
                            AnimatedBuilder(
                              animation: _introController,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(0, _introDone ? 0 : _logoY.value),
                                child: Opacity(
                                  opacity: _introDone ? 1.0 : _logoFade.value,
                                  child: child,
                                ),
                              ),
                              child: _buildTitle(),
                            ),
                            const SizedBox(height: 14),

                            FadeTransition(
                              opacity: _uiFadeController,
                              child: _buildTagline(),
                            ),
                            const SizedBox(height: 44),

                            FadeTransition(
                              opacity: _uiFadeController,
                              child: _buildDivider(),
                            ),
                            const SizedBox(height: 44),

                            FadeTransition(
                              opacity: _uiFadeController,
                              child: _buildStartButton(),
                            ),
                            const SizedBox(height: 16),

                            FadeTransition(
                              opacity: _uiFadeController,
                              child: _buildSubButtons(),
                            ),
                            const SizedBox(height: 32),

                            FadeTransition(
                              opacity: _uiFadeController,
                              child: _buildLeaderboard(),
                            ),
                            const SizedBox(height: 48),

                            FadeTransition(
                              opacity: _uiFadeController,
                              child: _buildFooter(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget builders ───────────────────────────────────────────────────────

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) {
        final glow = _glowController.value;
        return Text(
          'STARSHIP\nTROOPERZ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 68,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
            height: 1.1,
            color: Colors.white,
            shadows: [
              Shadow(
                color: const Color(0xFF00FF88).withAlpha(
                    ((0.35 + glow * 0.45) * 255).round()),
                blurRadius: 18 + glow * 18,
              ),
              Shadow(
                color: const Color(0xFF00CCFF).withAlpha(
                    ((0.15 + glow * 0.25) * 255).round()),
                blurRadius: 40 + glow * 24,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return GestureDetector(
      onTap: _showLoreDialog,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          '"WOULD YOU LIKE TO KNOW MORE?"',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 4,
            color: const Color(0xFF00FF88).withAlpha(210),
            fontStyle: FontStyle.italic,
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF00FF88).withAlpha(80),
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _line(80),
        const SizedBox(width: 14),
        _diamond(),
        const SizedBox(width: 14),
        _line(80),
      ],
    );
  }

  Widget _line(double w) =>
      Container(width: w, height: 1, color: const Color(0xFF00FF88).withAlpha(120));

  Widget _diamond() => Transform.rotate(
        angle: 0.785,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
          ),
        ),
      );

  Widget _buildStartButton() {
    return _GlowButton(
      label: 'INITIATE MISSION',
      onPressed: _startMission,
      primary: true,
    );
  }

  Widget _buildSubButtons() {
    return _GlowButton(
      label: 'CODEX',
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const CodexDialog(),
      ),
      primary: false,
    );
  }

  Widget _buildLeaderboard() {
    const entries = [
      ('CDR. VALERIA-7', 4840, 'ACCORD HERO'),
      ('SGT. DRAVEK', 4210, 'ROUGHNECK LEGEND'),
      ('CMD. ORYX-9', 3870, 'THE TRUTH'),
      ('LT. CASSEN', 3340, 'ACCORD HERO'),
      ('PVT. NORTH', 2980, 'ROUGHNECK LEGEND'),
    ];

    return SizedBox(
      width: 460,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 3, height: 9, color: const Color(0xFF00FF88)),
                  const SizedBox(width: 7),
                  const Text(
                    'GALACTIC LEADERBOARD',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 3,
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                ...entries.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Opacity(
                    opacity: 0.22,
                    child: Row(children: [
                      SizedBox(
                        width: 18,
                        child: Text('${e.key + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withAlpha(80),
                              letterSpacing: 1,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value.$1,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Text('${e.value.$2}',
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFFFFDD44))),
                      const SizedBox(width: 10),
                      Text(e.value.$3,
                          style: TextStyle(
                              fontSize: 8,
                              letterSpacing: 1,
                              color: Colors.white.withAlpha(70))),
                    ]),
                  ),
                )),
              ],
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(148),
                border: Border.all(color: const Color(0xFFFFDD44).withAlpha(55)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '◆   LEADERBOARD   ◆',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 6,
                        color: Color(0xFFFFDD44),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'COMING SOON — ACTIVATES ON DEPLOYMENT',
                      style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 2,
                          color: Colors.white.withAlpha(55)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(width: 1, height: 32, color: const Color(0xFF00FF88).withAlpha(60)),
        const SizedBox(height: 8),
        Text(
          'CIVIC ACCORD — CLASSIFIED DEPLOYMENT  •  v0.1',
          style: TextStyle(fontSize: 9, letterSpacing: 3, color: Colors.white.withAlpha(60)),
        ),
        const SizedBox(height: 4),
        Text(
          'Session-based. Closing this tab resets your run.',
          style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.white.withAlpha(35)),
        ),
      ],
    );
  }
}

// ─── Lore Dialog ──────────────────────────────────────────────────────────────

class _LoreDialog extends StatelessWidget {
  const _LoreDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF040814),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00FF88).withAlpha(120)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ACCORDNET  INTEL BULLETIN',
                style: TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF00FF88))),
            const SizedBox(height: 8),
            const Text('WOULD YOU LIKE\nTO KNOW MORE?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFF00FF88).withAlpha(60)),
            const SizedBox(height: 16),
            const Text(
              'The Civic Accord maintains order across seventeen inhabited systems. '
              'Service earns citizenship. Citizenship earns rights. The math is simple.\n\n'
              'The Chithari emerged from the outer reaches twelve years ago. '
              'They do not negotiate. They do not surrender. They do not stop.\n\n'
              'Or so the Accord broadcasts.\n\n'
              'Your mission: reach Accord Prime with the xenodata payload intact. '
              'Five sectors. Limited fuel and oxygen. A crew that watches every '
              'decision you make — and remembers.\n\n'
              '"The only good bug is a dead bug."\n'
              '— AccordNet Public Broadcast, Year 12',
              style: TextStyle(fontSize: 13, height: 1.75, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00FF88)),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('CLOSE BRIEFING',
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

// ─── Painters ─────────────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  const _ScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(26)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// ─── Shared UI Widgets ────────────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  const _GlowButton({
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.primary ? const Color(0xFF00FF88) : const Color(0xFF00AAFF);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          border: Border.all(
            color: accent.withAlpha(_hovered ? 255 : 160),
            width: 1.5,
          ),
          color: _hovered ? accent.withAlpha(25) : Colors.transparent,
          boxShadow: _hovered
              ? [BoxShadow(color: accent.withAlpha(60), blurRadius: 16, spreadRadius: 1)]
              : [],
        ),
        child: TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: widget.primary ? 52 : 28,
              vertical: widget.primary ? 18 : 12,
            ),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.primary ? 16 : 12,
              letterSpacing: widget.primary ? 5 : 3,
              color: widget.onPressed == null
                  ? accent.withAlpha(80)
                  : _hovered
                      ? Colors.white
                      : accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
