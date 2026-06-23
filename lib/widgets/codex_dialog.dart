import 'package:flutter/material.dart';

class CodexDialog extends StatelessWidget {
  const CodexDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF040814),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 620),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00FF88).withAlpha(120)),
        ),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCORDNET  SECURE ARCHIVE',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 4,
                        color: Color(0xFF00FF88),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'CODEX',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      color: const Color(0xFF00FF88).withAlpha(50),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              // ── Tab bar ───────────────────────────────────────────────
              Container(
                color: Colors.black.withAlpha(60),
                child: const TabBar(
                  labelColor: Color(0xFF00FF88),
                  unselectedLabelColor: Colors.white38,
                  indicatorColor: Color(0xFF00FF88),
                  indicatorWeight: 1.5,
                  labelStyle: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(text: 'MISSION'),
                    Tab(text: 'FACTIONS'),
                    Tab(text: 'CREW'),
                    Tab(text: 'RESOURCES'),
                  ],
                ),
              ),
              // ── Tab content ───────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: [
                    _TabPage(sections: _missionSections),
                    _TabPage(sections: _factionSections),
                    _TabPage(sections: _crewSections),
                    _TabPage(sections: _resourceSections),
                  ],
                ),
              ),
              // ── Footer ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: const Color(0xFF00FF88).withAlpha(40)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CLASSIFICATION: COMMANDER EYES ONLY',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        color: Colors.white.withAlpha(40),
                      ),
                    ),
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
                        'CLOSE',
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
      ),
    );
  }
}

// ─── Tab page layout ──────────────────────────────────────────────────────────

class _Section {
  final String heading;
  final String body;
  const _Section(this.heading, this.body);
}

class _TabPage extends StatelessWidget {
  final List<_Section> sections;
  const _TabPage({required this.sections});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 3,
                          height: 11,
                          color: const Color(0xFF00FF88),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.heading,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFF00FF88),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        s.body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.7,
                          color: Colors.white.withAlpha(210),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

const _missionSections = [
  _Section(
    'SITUATION',
    'You command the UES Vektara — a Civic Accord frigate assigned a priority '
    'delivery mission. A xenodata payload recovered from a Chithari wreck must '
    'reach Accord Prime, the seat of government, before enemy forces can '
    'intercept it. What the payload contains is above your clearance level.',
  ),
  _Section(
    'YOUR OBJECTIVE',
    'Navigate five contested sectors from Vektara Station to Accord Prime. '
    'Each sector is a node on the galactic map. Jumping between nodes costs '
    'fuel, oxygen, and rations. Trade posts along the way let you restock — '
    'if you have credits.',
  ),
  _Section(
    'HOW YOU WIN',
    'Reach Accord Prime with the payload intact and at least some of your crew '
    'alive. Your ending depends on the choices you made along the way: '
    'Accord Hero, Roughneck Legend, or something else entirely.',
  ),
  _Section(
    'HOW YOU LOSE',
    'Any one of these ends the run: hull destroyed, oxygen gone, rations '
    'exhausted, fuel depleted, crew mutiny (loyalty collapses), or civilian '
    'uprising (tension maxes out). The galaxy does not care which one gets '
    'you first.',
  ),
  _Section(
    'SESSION-BASED PLAY',
    'There is no mid-run save. Keep this tab open to continue your run. '
    'Closing the tab resets everything. Completing a full run unlocks '
    'save support in a future update.',
  ),
];

const _factionSections = [
  _Section(
    'THE CIVIC ACCORD',
    'The dominant human government spanning seventeen star systems. The Accord '
    'operates on a simple principle: military service earns citizenship, and '
    'citizenship earns rights. Those who do not serve are civilians — they '
    'live under Accord protection but hold no vote and no rank.\n\n'
    'The Accord controls the broadcast networks, the trade lanes, and the '
    'military. They are the law. Whether they are right is your question to '
    'answer.',
  ),
  _Section(
    'THE CHITHARI',
    'An insectoid species that emerged from the outer reaches twelve years ago. '
    'The Accord broadcasts call them mindless destroyers — hostile, '
    'coordinated, relentless. Accord doctrine is simple: exterminate on sight.\n\n'
    'Field commanders have noted they sometimes retreat instead of fighting '
    'to the last. Some xenobiologists believe there is more going on. The '
    'Accord has not released their research.',
  ),
  _Section(
    'CITIZENS VS CIVILIANS',
    'Your crew is split. Citizens have completed military service and are '
    'fully invested in the Accord mission. Civilians are non-combat personnel '
    'who signed on for pay or necessity.\n\n'
    'Citizens and civilians react differently to your decisions. A call to '
    'fight may boost citizen loyalty but spike civilian fear. A diplomatic '
    'choice may calm civilians but read as weakness to citizens. Managing '
    'both is the job.',
  ),
  _Section(
    'THE TRUTH',
    'Certain decisions unlock a hidden thread. The Accord narrative has gaps. '
    'Pay attention to what you find out there — and what the Accord asks you '
    'to ignore.',
  ),
];

const _crewSections = [
  _Section(
    'CREW STATS',
    'Each crew member has three personal stats:\n\n'
    'LOYALTY — how much they trust your command. If the crew average '
    'drops below 15, they mutiny and the run ends.\n\n'
    'FEAR — how scared they are. High fear makes crew erratic and '
    'amplifies tension.\n\n'
    'HOPE — belief that the mission matters. Low hope drags loyalty down '
    'over time.',
  ),
  _Section(
    'CIVILIAN TENSION',
    'A ship-wide pressure gauge (0–100). Civilian crew members push this up '
    'when you make harsh or authoritarian choices. At 70 you will see warning '
    'signs. At 90 the situation is critical. At 100 the civilians seize the '
    'ship — run over.',
  ),
  _Section(
    'YOUR BACKGROUND',
    'The background you choose at the start shapes your crew\'s starting '
    'loyalty and your credit reserve:\n\n'
    'VANGUARD CONSCRIPT — career soldier. Citizens respect you immediately. '
    'Starts with a modest credit bonus.\n\n'
    'CIVIC OFFICER — administrator turned commander. Diplomatic credibility, '
    'largest starting credit reserve.\n\n'
    'MEDTECH SPECIALIST — field medic. Crew trusts you with their lives. '
    'Small credit bonus, high crew goodwill.',
  ),
  _Section(
    'CREW ENCOUNTERS',
    'Some encounters let specific crew members act. Their loyalty, fear, and '
    'background influence outcomes. A low-loyalty crew member sent on a '
    'dangerous task may not follow through. A terrified civilian may refuse '
    'orders under pressure.',
  ),
];

const _resourceSections = [
  _Section(
    'HULL',
    'The ship\'s structural integrity. Damaged by combat and certain '
    'encounter choices. Hull repair kits are available at trade posts. '
    'Hull at zero means the ship is destroyed — run over.',
  ),
  _Section(
    'FUEL',
    'Required for every jump between nodes. Each jump costs fuel. Running '
    'out leaves the ship adrift in hostile space — run over. Trade posts '
    'stock fuel canisters. Plan your route.',
  ),
  _Section(
    'OXYGEN',
    'Life support reserves. Depleted by every jump. A damaged O2 system '
    'or a bad encounter can accelerate the drain. O2 filter packs are '
    'available at trade posts. Zero oxygen means the crew does not '
    'survive — run over.',
  ),
  _Section(
    'RATIONS',
    'Food supply for the crew. Consumed on every jump. Starvation destroys '
    'morale before it kills — expect loyalty to collapse as rations run low. '
    'Ration packs are the cheapest item at trade posts.',
  ),
  _Section(
    'CREDITS  ₢',
    'The Accord\'s currency. Earned through encounter choices — salvage '
    'contracts, intelligence deals, compliance rewards. Spent at trade posts '
    'on supplies and repairs. Your background determines your starting reserve. '
    'Spend wisely; trade posts are not on every node.',
  ),
  _Section(
    'AMMO & MEDICINE',
    'Secondary resources consumed in specific encounters. Ammo for combat '
    'situations, medicine for crew injuries and morale crises. Both can be '
    'purchased at trade posts. Running low limits your choices when it '
    'matters most.',
  ),
];
