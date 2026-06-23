import 'dart:ui';

enum StarSystemType { station, planet, debris, jumpgate }

class StarSystem {
  final String id;
  final String name;
  final String subtitle;
  final Offset position; // normalized 0.0–1.0
  final List<String> connections;
  final int sector;
  final StarSystemType type;
  final bool isShop;
  final String? npcName;
  final String? npcRole;

  const StarSystem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.position,
    required this.connections,
    required this.sector,
    required this.type,
    this.isShop = false,
    this.npcName,
    this.npcRole,
  });

  bool get hasNpc => npcName != null;

  Offset pixelPos(Size canvasSize) =>
      Offset(position.dx * canvasSize.width, position.dy * canvasSize.height);
}

// ─── Galaxy maze: 3 lanes (upper / middle / lower), 5 sectors ─────────────────
//
//  UPPER   kaveth ──── graveyard ──── kethreach ─────────╮
//                 ╲  ╱            ╲  ╱          ╲        │
//  MID     relay ──── wreckfield ──── vanguard ── accordprime
//         ╱      ╲  ╱            ╲  ╱          ╲        │
//  LOWER   drift ──── deadzone ────── solune ────────────╯
//
//  vektara (start, shop) fans out to kaveth, relay, drift
// ──────────────────────────────────────────────────────────────────────────────

const kGalaxySystems = <StarSystem>[
  // ── Sector 1 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'vektara',
    name: 'Vektara Station',
    subtitle: 'Inner System Hub',
    position: Offset(0.07, 0.50),
    connections: ['kaveth', 'relay', 'drift'],
    sector: 1,
    type: StarSystemType.station,
    isShop: true,
    npcName: 'Director Oslo',
    npcRole: 'Accord Attaché',
  ),

  // ── Sector 2 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'kaveth',
    name: 'New Kaveth',
    subtitle: 'Transit Corridor — Upper Lane',
    position: Offset(0.29, 0.16),
    connections: ['vektara', 'graveyard', 'relay'],
    sector: 2,
    type: StarSystemType.planet,
    npcName: 'Commander Tesh',
    npcRole: 'Fleet Liaison',
  ),
  StarSystem(
    id: 'relay',
    name: 'Relay Beacon Sigma',
    subtitle: 'Accord Supply Post',
    position: Offset(0.31, 0.50),
    connections: ['vektara', 'kaveth', 'drift', 'wreckfield'],
    sector: 2,
    type: StarSystemType.station,
    isShop: true,
    npcName: 'Quartermaster Pol',
    npcRole: 'Supply Corps',
  ),
  StarSystem(
    id: 'drift',
    name: 'The Drift',
    subtitle: 'Debris Field — Lower Lane',
    position: Offset(0.29, 0.82),
    connections: ['vektara', 'relay', 'deadzone'],
    sector: 2,
    type: StarSystemType.debris,
  ),

  // ── Sector 3 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'graveyard',
    name: 'The Graveyard',
    subtitle: 'Old War Zone — Upper Lane',
    position: Offset(0.52, 0.14),
    connections: ['kaveth', 'wreckfield', 'kethreach'],
    sector: 3,
    type: StarSystemType.debris,
  ),
  StarSystem(
    id: 'wreckfield',
    name: 'Kaveth Wreckfield',
    subtitle: 'Contested Zone',
    position: Offset(0.53, 0.50),
    connections: ['relay', 'graveyard', 'deadzone', 'kethreach', 'vanguard'],
    sector: 3,
    type: StarSystemType.debris,
    isShop: true,
    npcName: 'Salvager Moxen',
    npcRole: 'Independent Trader',
  ),
  StarSystem(
    id: 'deadzone',
    name: 'The Deadzone',
    subtitle: 'Uncharted Hazard — Lower Lane',
    position: Offset(0.52, 0.84),
    connections: ['drift', 'wreckfield', 'solune'],
    sector: 3,
    type: StarSystemType.debris,
  ),

  // ── Sector 4 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'kethreach',
    name: "Keth'ari Reach",
    subtitle: 'Alien Border Zone — Upper Lane',
    position: Offset(0.72, 0.15),
    connections: ['graveyard', 'wreckfield', 'vanguard', 'accordprime'],
    sector: 4,
    type: StarSystemType.planet,
    npcName: 'Envoy Shiral',
    npcRole: "Keth'ari Speaker",
  ),
  StarSystem(
    id: 'vanguard',
    name: 'Accord Vanguard',
    subtitle: 'Forward Operating Base',
    position: Offset(0.73, 0.52),
    connections: ['kethreach', 'wreckfield', 'solune', 'accordprime'],
    sector: 4,
    type: StarSystemType.station,
    isShop: true,
    npcName: 'Admiral Cress',
    npcRole: 'Accord Navy',
  ),
  StarSystem(
    id: 'solune',
    name: 'Solune Expanse',
    subtitle: 'Deep Space — Lower Lane',
    position: Offset(0.71, 0.84),
    connections: ['deadzone', 'vanguard', 'accordprime'],
    sector: 4,
    type: StarSystemType.planet,
  ),

  // ── Sector 5 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'accordprime',
    name: 'Accord Prime',
    subtitle: 'Final Objective',
    position: Offset(0.92, 0.50),
    connections: ['kethreach', 'vanguard', 'solune'],
    sector: 5,
    type: StarSystemType.jumpgate,
    npcName: 'High Director Vale',
    npcRole: 'Accord Command',
  ),
];

// ─── NPC dialogue per system ──────────────────────────────────────────────────
const kSystemDialogue = <String, List<Map<String, String>>>{
  'vektara': [
    {
      'speaker': 'Director Oslo',
      'role': 'Accord Attaché',
      'portrait': 'official',
      'text':
          'Commander. Your mission parameters are clear — reach Accord Prime and deliver the xenodata payload. Do not deviate from the approved route.',
    },
    {
      'speaker': 'Director Oslo',
      'role': 'Accord Attaché',
      'portrait': 'official',
      'text':
          'The crew roster includes Civic Accord observers. Their reports go directly to High Command. I trust you understand what that means.',
    },
  ],
  'kaveth': [
    {
      'speaker': 'Commander Tesh',
      'role': 'Fleet Liaison',
      'portrait': 'commander',
      'text':
          'You made it through the inner corridor. Word of warning — the Accord\'s communication blackout in Sector 3 isn\'t a technical fault. Something out there is jamming our signals.',
    },
  ],
  'relay': [
    {
      'speaker': 'Quartermaster Pol',
      'role': 'Supply Corps',
      'portrait': 'trader',
      'text':
          'Commander. Sigma Relay stocks are limited but I can move product. Credits talk out here — AccordNet requisitions don\'t get answered fast enough to matter.',
    },
  ],
  'wreckfield': [
    {
      'speaker': 'Salvager Moxen',
      'role': 'Independent Trader',
      'portrait': 'trader',
      'text':
          'Nice ship. Shame about the war. You\'re headed to Keth\'ari space? They don\'t shoot first, Commander. That\'s not what the Accord tells you, but I\'ve been working this field a long time.',
    },
  ],
  'kethreach': [
    {
      'speaker': 'Envoy Shiral',
      'role': "Keth'ari Speaker",
      'portrait': 'alien',
      'text':
          '[ Resonance field coalesces into meaning ] ...You carry pain, Commander. Your crew carries more. We do not wish this war. But we will not be extinguished quietly.',
    },
    {
      'speaker': 'Envoy Shiral',
      'role': "Keth'ari Speaker",
      'portrait': 'alien',
      'text':
          '[ The resonance deepens ] ...Ask your Accord why the Solune migration ended. Ask what they found in the Graveyard. The answer changes everything.',
    },
  ],
  'vanguard': [
    {
      'speaker': 'Admiral Cress',
      'role': 'Accord Navy',
      'portrait': 'commander',
      'text':
          'You made it through the Reach. Good. Accord Vanguard is the last friendly port before the final push. Stock up if you\'re able — Accord Prime won\'t wait.',
    },
  ],
  'accordprime': [
    {
      'speaker': 'High Director Vale',
      'role': 'Accord Command',
      'portrait': 'official',
      'text':
          'You\'ve arrived. The Accord thanks you for your service, Commander. The xenodata you\'ve gathered will determine the next phase of the campaign.',
    },
    {
      'speaker': 'High Director Vale',
      'role': 'Accord Command',
      'portrait': 'official',
      'text':
          'What you discovered in Keth\'ari space must not leave this chamber. The public narrative of this war is... fragile. Do you understand, Commander?',
    },
  ],
};
