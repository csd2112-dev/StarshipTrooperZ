import 'dart:async';
import 'package:flutter/material.dart';

enum PortraitType { accordOfficial, crewMember, alien, trader, commander }

class DialogueLine {
  final String speakerName;
  final String speakerRole;
  final PortraitType portrait;
  final String text;

  const DialogueLine({
    required this.speakerName,
    required this.speakerRole,
    required this.portrait,
    required this.text,
  });
}

class DialogueBox extends StatefulWidget {
  final List<DialogueLine> lines;
  final VoidCallback onComplete;

  const DialogueBox({super.key, required this.lines, required this.onComplete});

  @override
  State<DialogueBox> createState() => _DialogueBoxState();
}

class _DialogueBoxState extends State<DialogueBox>
    with SingleTickerProviderStateMixin {
  int _lineIndex = 0;
  String _displayedText = '';
  int _charIndex = 0;
  bool _lineComplete = false;
  Timer? _typeTimer;
  late AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 550))
          ..repeat(reverse: true);
    _startTyping();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _blinkCtrl.dispose();
    super.dispose();
  }

  DialogueLine get _current => widget.lines[_lineIndex];

  void _startTyping() {
    _displayedText = '';
    _charIndex = 0;
    _lineComplete = false;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 26), (t) {
      if (_charIndex >= _current.text.length) {
        t.cancel();
        if (mounted) setState(() => _lineComplete = true);
      } else {
        if (mounted) {
          setState(() {
            _displayedText = _current.text.substring(0, ++_charIndex);
          });
        }
      }
    });
  }

  void _advance() {
    if (!_lineComplete) {
      // Skip to end of current line
      _typeTimer?.cancel();
      setState(() {
        _displayedText = _current.text;
        _lineComplete = true;
      });
      return;
    }
    if (_lineIndex < widget.lines.length - 1) {
      setState(() => _lineIndex++);
      _startTyping();
    } else {
      widget.onComplete();
    }
  }

  Color _portraitColor(PortraitType p) => switch (p) {
        PortraitType.accordOfficial => const Color(0xFF00AAFF),
        PortraitType.crewMember => const Color(0xFF00FF88),
        PortraitType.alien => const Color(0xFFCC88FF),
        PortraitType.trader => const Color(0xFFFFAA00),
        PortraitType.commander => const Color(0xFFFF6644),
      };

  IconData _portraitIcon(PortraitType p) => switch (p) {
        PortraitType.accordOfficial => Icons.account_balance,
        PortraitType.crewMember => Icons.person,
        PortraitType.alien => Icons.blur_on,
        PortraitType.trader => Icons.swap_horiz,
        PortraitType.commander => Icons.military_tech,
      };

  @override
  Widget build(BuildContext context) {
    final line = _current;
    final pColor = _portraitColor(line.portrait);
    final isLast = _lineIndex == widget.lines.length - 1;

    return GestureDetector(
      onTap: _advance,
      child: Container(
        margin: const EdgeInsets.all(12),
        height: 148,
        decoration: BoxDecoration(
          color: const Color(0xFF020B18).withAlpha(240),
          border: Border.all(color: pColor.withAlpha(200), width: 1.5),
          boxShadow: [
            BoxShadow(color: pColor.withAlpha(40), blurRadius: 24, spreadRadius: 1),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Portrait panel
            Container(
              width: 112,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                border: Border(right: BorderSide(color: pColor.withAlpha(100))),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: pColor.withAlpha(180), width: 1.5),
                      color: pColor.withAlpha(18),
                    ),
                    child: Icon(_portraitIcon(line.portrait), color: pColor, size: 30),
                  ),
                  const SizedBox(height: 9),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      line.speakerName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.2,
                          color: pColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      line.speakerRole,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 7, color: Colors.white.withAlpha(80)),
                    ),
                  ),
                ],
              ),
            ),
            // Text panel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                child: Stack(
                  children: [
                    Text(
                      _displayedText,
                      style: const TextStyle(
                          fontSize: 13, height: 1.65, color: Colors.white),
                    ),
                    if (_lineComplete)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: _blinkCtrl,
                          builder: (_, __) => Opacity(
                            opacity: 0.4 + _blinkCtrl.value * 0.6,
                            child: Text(
                              isLast ? '▼  CLOSE' : '▼  CONTINUE',
                              style: TextStyle(
                                  fontSize: 9, letterSpacing: 2, color: pColor),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
