import 'package:flutter/material.dart';
import '../models/game_state.dart';

// ─── Crew Profile Dialog ──────────────────────────────────────────────────────

class CrewProfileDialog extends StatefulWidget {
  final CrewMember member;
  final GameState gs;
  final VoidCallback onChanged;

  const CrewProfileDialog({
    super.key,
    required this.member,
    required this.gs,
    required this.onChanged,
  });

  @override
  State<CrewProfileDialog> createState() => _CrewProfileDialogState();
}

class _CrewProfileDialogState extends State<CrewProfileDialog> {
  CrewMember get _m => widget.member;
  GameState get _gs => widget.gs;

  String? _resultMessage;
  bool _showingDutyPicker = false;

  void _talk() {
    if (_m.interactedThisSector) return;
    setState(() {
      _m.interactedThisSector = true;
      _m.loyalty = (_m.loyalty + 3).clamp(0, 100);
      _m.hope = (_m.hope + 2).clamp(0, 100);
      _m.fear = (_m.fear - 2).clamp(0, 100);
      _resultMessage = _m.talkLine;
    });
    widget.onChanged();
  }

  void _giftRations() {
    if (_m.interactedThisSector || _gs.rations < 5) return;
    setState(() {
      _m.interactedThisSector = true;
      _gs.rations -= 5;
      _m.loyalty = (_m.loyalty + 8).clamp(0, 100);
      _m.hope = (_m.hope + 5).clamp(0, 100);
      _resultMessage = '"These rations mean more than you know. Thank you, Commander."';
      _gs.addLog('${_m.name} received a ration gift. Loyalty +8.');
    });
    widget.onChanged();
  }

  void _giftCredits() {
    if (_m.interactedThisSector || _gs.credits < 10) return;
    setState(() {
      _m.interactedThisSector = true;
      _gs.credits -= 10;
      _m.loyalty = (_m.loyalty + 10).clamp(0, 100);
      _resultMessage = '"Credits. I\'ll remember this, Commander."';
      _gs.addLog('${_m.name} received a credit gift ₢10. Loyalty +10.');
    });
    widget.onChanged();
  }

  void _assignDuty(CrewDuty duty) {
    setState(() {
      _showingDutyPicker = false;
      final isNew = _m.assignedDuty != duty;
      _m.assignedDuty = duty;
      if (isNew) {
        _m.loyalty = (_m.loyalty + 3).clamp(0, 100);
        _resultMessage =
            '"${duty.label} station. Understood, Commander. I\'ll make it count."';
        _gs.addLog('${_m.name} assigned to ${duty.label}. Loyalty +3.');
        widget.onChanged();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCitizen = _m.status == CrewStatus.citizen;
    final statusColor =
        isCitizen ? const Color(0xFF00AAFF) : const Color(0xFFFFAA00);
    final interacted = _m.interactedThisSector;

    return Dialog(
      backgroundColor: const Color(0xFF040814),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00FF88).withAlpha(120)),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF00FF88).withAlpha(50),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CREW DOSSIER',
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 4,
                            color: Color(0xFF00FF88),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _m.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _m.role,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(120),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Badge(_m.statusLabel, statusColor),
                      if (_m.assignedDuty != null) ...[
                        const SizedBox(height: 6),
                        _Badge(_m.assignedDuty!.label.toUpperCase(),
                            const Color(0xFFCC88FF)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Morale stats
                    _SectionHead('MORALE'),
                    const SizedBox(height: 10),
                    _StatRow('LOYALTY', _m.loyalty, _loyaltyColor(_m.loyalty),
                        _m.loyaltyLabel),
                    _StatRow('FEAR', _m.fear, const Color(0xFFFF8844), _fearLabel(_m.fear)),
                    _StatRow('HOPE', _m.hope, const Color(0xFF00AAFF), _hopeLabel(_m.hope)),
                    if (_m.trauma > 0)
                      _StatRow('TRAUMA', _m.trauma, const Color(0xFFCC4444), '${_m.trauma}%'),
                    const SizedBox(height: 18),

                    // Skills
                    _SectionHead('SKILLS'),
                    const SizedBox(height: 10),
                    _SkillRow('COMBAT', _m.combatSkill),
                    _SkillRow('TECHNICAL', _m.techSkill),
                    _SkillRow('MEDICAL', _m.medicalSkill),
                    _SkillRow('DIPLOMATIC', _m.diplomaticSkill),
                    const SizedBox(height: 18),

                    // Assigned duty
                    _SectionHead('ASSIGNED DUTY'),
                    const SizedBox(height: 10),
                    if (!_showingDutyPicker) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _m.assignedDuty == null
                                ? Text(
                                    'No duty assigned.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withAlpha(80),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _m.assignedDuty!.label,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFCC88FF),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _m.assignedDuty!.description,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withAlpha(120),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 12),
                          _OutlineBtn(
                            label: _m.assignedDuty == null
                                ? 'ASSIGN'
                                : 'REASSIGN',
                            color: const Color(0xFFCC88FF),
                            onTap: () =>
                                setState(() => _showingDutyPicker = true),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Duty picker
                      ...CrewDuty.values.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _DutyOption(
                          duty: d,
                          selected: _m.assignedDuty == d,
                          onTap: () => _assignDuty(d),
                        ),
                      )),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showingDutyPicker = false),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: Colors.white.withAlpha(80),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Interactions
                    _SectionHead(interacted
                        ? 'INTERACTIONS  •  USED THIS SECTOR'
                        : 'INTERACTIONS  •  1 PER SECTOR'),
                    const SizedBox(height: 10),
                    if (_resultMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF88).withAlpha(10),
                          border: Border.all(
                            color: const Color(0xFF00FF88).withAlpha(60),
                          ),
                        ),
                        child: Text(
                          _resultMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        _InteractBtn(
                          label: 'TALK',
                          sub: 'Free',
                          color: const Color(0xFF00FF88),
                          enabled: !interacted,
                          onTap: _talk,
                        ),
                        const SizedBox(width: 8),
                        _InteractBtn(
                          label: 'GIFT RATIONS',
                          sub: '−5 rations',
                          color: const Color(0xFFFFAA00),
                          enabled: !interacted && _gs.rations >= 5,
                          onTap: _giftRations,
                        ),
                        const SizedBox(width: 8),
                        _InteractBtn(
                          label: 'GIFT CREDITS',
                          sub: '−₢10',
                          color: const Color(0xFFFFDD44),
                          enabled: !interacted && _gs.credits >= 10,
                          onTap: _giftCredits,
                        ),
                      ],
                    ),

                    // Trauma events
                    if (_m.traumaEvents.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SectionHead('TRAUMA RECORD'),
                      const SizedBox(height: 8),
                      ..._m.traumaEvents.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '> $e',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.5,
                            color: const Color(0xFFFF8844).withAlpha(180),
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const Color(0xFF00FF88).withAlpha(40)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00FF88)),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      'DISMISS',
                      style: TextStyle(
                        letterSpacing: 3,
                        fontSize: 11,
                        color: Color(0xFF00FF88),
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

  Color _loyaltyColor(int v) {
    if (v >= 60) return const Color(0xFF00FF88);
    if (v >= 35) return const Color(0xFFFFAA00);
    return const Color(0xFFFF4444);
  }

  String _fearLabel(int v) {
    if (v < 20) return 'Calm';
    if (v < 45) return 'Tense';
    if (v < 70) return 'Scared';
    return 'Terrified';
  }

  String _hopeLabel(int v) {
    if (v >= 70) return 'Optimistic';
    if (v >= 45) return 'Hopeful';
    if (v >= 25) return 'Uncertain';
    return 'Despairing';
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHead extends StatelessWidget {
  final String label;
  const _SectionHead(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 9, color: const Color(0xFF00FF88)),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 3,
          color: Color(0xFF00FF88),
          fontWeight: FontWeight.bold,
        ),
      ),
    ]);
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final String statusText;
  const _StatRow(this.label, this.value, this.color, this.statusText);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: Colors.white.withAlpha(130),
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withAlpha(20),
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.zero,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withAlpha(80),
            letterSpacing: 1,
          ),
        ),
      ]),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String label;
  final int value;
  const _SkillRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final Color color = value >= 65
        ? const Color(0xFF00FF88)
        : value >= 40
            ? const Color(0xFF00AAFF)
            : Colors.white.withAlpha(100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: Colors.white.withAlpha(100),
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withAlpha(15),
            color: color,
            minHeight: 3,
            borderRadius: BorderRadius.zero,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120)),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(160)),
        color: color.withAlpha(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9, letterSpacing: 1, color: color)),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(180)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DutyOption extends StatefulWidget {
  final CrewDuty duty;
  final bool selected;
  final VoidCallback onTap;
  const _DutyOption({required this.duty, required this.selected, required this.onTap});

  @override
  State<_DutyOption> createState() => _DutyOptionState();
}

class _DutyOptionState extends State<_DutyOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFCC88FF);
    final active = widget.selected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
                color: active ? accent : accent.withAlpha(50)),
            color: active ? accent.withAlpha(18) : Colors.transparent,
          ),
          child: Row(children: [
            if (widget.selected)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('◆',
                    style: TextStyle(fontSize: 9, color: accent)),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.duty.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: active ? accent : Colors.white,
                    ),
                  ),
                  Text(
                    widget.duty.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withAlpha(100),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InteractBtn extends StatefulWidget {
  final String label;
  final String sub;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _InteractBtn({
    required this.label,
    required this.sub,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractBtn> createState() => _InteractBtnState();
}

class _InteractBtnState extends State<_InteractBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.enabled
        ? ((_hovered) ? Colors.white : widget.color)
        : Colors.white.withAlpha(40);
    final border =
        widget.enabled ? widget.color.withAlpha(_hovered ? 255 : 140) : Colors.white.withAlpha(25);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            color: (_hovered && widget.enabled)
                ? widget.color.withAlpha(18)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.sub,
                style: TextStyle(
                  fontSize: 8,
                  color: widget.enabled
                      ? widget.color.withAlpha(140)
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
