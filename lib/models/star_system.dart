import 'dart:ui';

enum StarSystemType { station, planet, debris, jumpgate }

enum PathEventType { hazard, bonus, intel }

class PathEvent {
  final String title;
  final String flavor;
  final PathEventType type;
  final int hullDelta;
  final int fuelDelta;
  final int rationsDelta;
  final int oxygenDelta;
  final int creditsDelta;
  final int ammoDelta;
  final int medicineDelta;
  final int loyaltyDelta;
  final int fearDelta;

  const PathEvent({
    required this.title,
    required this.flavor,
    required this.type,
    this.hullDelta = 0,
    this.fuelDelta = 0,
    this.rationsDelta = 0,
    this.oxygenDelta = 0,
    this.creditsDelta = 0,
    this.ammoDelta = 0,
    this.medicineDelta = 0,
    this.loyaltyDelta = 0,
    this.fearDelta = 0,
  });
}

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

// ─── Galaxy layout: 3 lanes × 5 columns on a clean grid ──────────────────────
//
//  COL      1         2            3              4            5
//  UPPER  [vektara] kaveth ──── graveyard ──── kethreach ──╮
//           ╱╲    ╲  ╱   ╲     ╱   ╲    ╲     ╱    ╲      │
//  MID    start   relay ──── wreckfield ──── vanguard ── accordprime
//           ╲╱    ╱   ╲     ╱   ╲    ╲     ╱    ╲      │
//  LOWER        drift ──── deadzone ────── solune ──────╯
//
//  Lane y-positions: upper 0.15  middle 0.50  lower 0.83
//  Col x-positions:  0.07  0.27   0.50         0.75   0.93
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
    position: Offset(0.27, 0.15),
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
    position: Offset(0.27, 0.50),
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
    position: Offset(0.27, 0.83),
    connections: ['vektara', 'relay', 'deadzone'],
    sector: 2,
    type: StarSystemType.debris,
  ),

  // ── Sector 3 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'graveyard',
    name: 'The Graveyard',
    subtitle: 'Old War Zone — Upper Lane',
    position: Offset(0.50, 0.15),
    connections: ['kaveth', 'wreckfield', 'kethreach'],
    sector: 3,
    type: StarSystemType.debris,
  ),
  StarSystem(
    id: 'wreckfield',
    name: 'Kaveth Wreckfield',
    subtitle: 'Contested Zone',
    position: Offset(0.50, 0.50),
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
    position: Offset(0.50, 0.83),
    connections: ['drift', 'wreckfield', 'solune'],
    sector: 3,
    type: StarSystemType.debris,
  ),

  // ── Sector 4 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'kethreach',
    name: "Keth'ari Reach",
    subtitle: 'Alien Border Zone — Upper Lane',
    position: Offset(0.75, 0.15),
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
    position: Offset(0.75, 0.50),
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
    position: Offset(0.75, 0.83),
    connections: ['deadzone', 'vanguard', 'accordprime'],
    sector: 4,
    type: StarSystemType.planet,
  ),

  // ── Sector 5 ──────────────────────────────────────────────────────────────
  StarSystem(
    id: 'accordprime',
    name: 'Accord Prime',
    subtitle: 'Final Objective',
    position: Offset(0.93, 0.50),
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

// ─── Path events per connection ───────────────────────────────────────────────
// Keys are sorted node-id pairs joined with '-'. Difficulty scales by sector.

const kPathEvents = <String, List<PathEvent>>{

  // ── Sector 1 → 2 (mild) ─────────────────────────────────────────────────

  'kaveth-vektara': [
    PathEvent(
      title: 'Accord Patrol Checkpoint',
      flavor: 'A patrol frigate flags your transponder. Standard inspection costs time and fuel.',
      type: PathEventType.hazard,
      fuelDelta: -4,
    ),
  ],

  'relay-vektara': [
    PathEvent(
      title: 'Emergency Supply Cache',
      flavor: 'An Accord waypoint beacon is broadcasting. The sealed cache inside is still good.',
      type: PathEventType.bonus,
      rationsDelta: 10,
      fuelDelta: 3,
    ),
  ],

  'drift-vektara': [
    PathEvent(
      title: 'Scattered Debris Field',
      flavor: 'Hull plating takes minor impacts crossing the outer belt. Nothing catastrophic — yet.',
      type: PathEventType.hazard,
      hullDelta: -5,
    ),
    PathEvent(
      title: 'Drifter Supply Pod',
      flavor: 'A pressurized container tumbles out of the field. The scavenger code on the side has been scratched off.',
      type: PathEventType.bonus,
      creditsDelta: 12,
      rationsDelta: 5,
    ),
  ],

  // ── Sector 2 → 3 (medium) ────────────────────────────────────────────────

  'graveyard-kaveth': [
    PathEvent(
      title: 'Chithari Scout Formation',
      flavor: 'Three alien scouts shadow your jump before peeling away. They know you\'re here.',
      type: PathEventType.intel,
      fearDelta: 5,
    ),
    PathEvent(
      title: 'Drive Thermal Vents',
      flavor: 'Residual radiation from the old war zone destabilizes your jump drive briefly.',
      type: PathEventType.hazard,
      fuelDelta: -7,
      hullDelta: -4,
    ),
  ],

  'relay-wreckfield': [
    PathEvent(
      title: 'Debris Impact',
      flavor: 'A hull fragment from a destroyed cruiser strikes your forward plating at speed.',
      type: PathEventType.hazard,
      hullDelta: -8,
    ),
    PathEvent(
      title: 'Abandoned Cargo Container',
      flavor: 'Pressurized and still sealed. The manifest inside reads: "Priority Accord Shipment — Do Not Open." You open it.',
      type: PathEventType.bonus,
      creditsDelta: 18,
      ammoDelta: 10,
    ),
  ],

  'deadzone-drift': [
    PathEvent(
      title: 'Ion Electrical Storm',
      flavor: 'The storm comes with no warning. Power stutters across every system. You ride it out.',
      type: PathEventType.hazard,
      hullDelta: -10,
      fuelDelta: -6,
    ),
    PathEvent(
      title: 'Distress Signal',
      flavor: 'Old, looping, probably automated. But the supply pod attached to the beacon is real.',
      type: PathEventType.bonus,
      rationsDelta: 8,
      medicineDelta: 8,
    ),
  ],

  'drift-relay': [
    PathEvent(
      title: 'Ionized Fuel Pocket',
      flavor: 'Your nav system picks up a dense ionized pocket. A quick scoop nets usable fuel.',
      type: PathEventType.bonus,
      fuelDelta: 6,
    ),
  ],

  'graveyard-wreckfield': [
    PathEvent(
      title: 'Dense Debris Cloud',
      flavor: 'Navigation at half-speed through the thickest part of the old battle zone.',
      type: PathEventType.hazard,
      hullDelta: -6,
      fuelDelta: -3,
    ),
  ],

  'deadzone-wreckfield': [
    PathEvent(
      title: 'Electromagnetic Anomaly',
      flavor: 'Sensors go dark for eleven minutes. When they come back, crew morale has slipped.',
      type: PathEventType.hazard,
      fearDelta: 6,
      oxygenDelta: -4,
    ),
  ],

  // ── Sector 3 → 4 (hard) ──────────────────────────────────────────────────

  'graveyard-kethreach': [
    PathEvent(
      title: 'Wraith Squadron Intercept',
      flavor: 'Eight unidentified fighters appear on approach. They hold formation — and fire twice. You take the hit and run.',
      type: PathEventType.hazard,
      hullDelta: -15,
      ammoDelta: -12,
      fearDelta: 10,
    ),
    PathEvent(
      title: 'Old War Relics',
      flavor: 'A derelict carrier from the first Chithari contact drifts past. Its vault is cracked open.',
      type: PathEventType.bonus,
      creditsDelta: 25,
      loyaltyDelta: 3,
    ),
  ],

  'kethreach-wreckfield': [
    PathEvent(
      title: "Keth'ari Resonance Burst",
      flavor: 'An alien resonance pulse scrambles your ship\'s sensors and stresses the O2 lines. Crew reports headaches.',
      type: PathEventType.hazard,
      oxygenDelta: -10,
      fearDelta: 8,
      hullDelta: -5,
    ),
    PathEvent(
      title: 'Abandoned Mining Station',
      flavor: 'Long-evacuated, but life support modules are intact. The O2 scrubbers are worth more than the rest of the ship combined.',
      type: PathEventType.bonus,
      oxygenDelta: 12,
      medicineDelta: 6,
    ),
  ],

  'vanguard-wreckfield': [
    PathEvent(
      title: 'Accord Escort Redeployment',
      flavor: 'An escort wing meets you and then pulls away on new orders. Your crew is not reassured.',
      type: PathEventType.hazard,
      fearDelta: 5,
      loyaltyDelta: -4,
    ),
    PathEvent(
      title: 'Accord Supply Request',
      flavor: '"Commander — Vanguard requisitions ten rations for the forward post. It\'s not a request." You comply.',
      type: PathEventType.hazard,
      rationsDelta: -10,
      loyaltyDelta: 3,
    ),
  ],

  'deadzone-solune': [
    PathEvent(
      title: 'The Void Silence',
      flavor: 'No signals, no ships, no debris. Nothing for eleven hours. The silence gets into your crew.',
      type: PathEventType.hazard,
      fearDelta: 9,
      loyaltyDelta: -5,
    ),
    PathEvent(
      title: 'Hull Micro-fracture Event',
      flavor: 'The pressure differential catches a hairline crack in the outer plating. Emergency patch holds — barely.',
      type: PathEventType.hazard,
      hullDelta: -16,
      oxygenDelta: -9,
    ),
  ],

  'kaveth-relay': [],
  'solune-vanguard': [],

  // ── Sector 4 → 5 (very hard) ─────────────────────────────────────────────

  'accordprime-kethreach': [
    PathEvent(
      title: 'Chithari Interdiction Fleet',
      flavor: 'A full alien interdiction wing drops out of FTL directly in your path. You fight through. The cost is severe.',
      type: PathEventType.hazard,
      hullDelta: -22,
      ammoDelta: -18,
      fearDelta: 15,
      oxygenDelta: -6,
    ),
    PathEvent(
      title: 'Final Approach Barricade',
      flavor: 'Accord military cordon. They board, they inspect, they take what they want. "Security protocols," they say.',
      type: PathEventType.hazard,
      rationsDelta: -12,
      creditsDelta: -15,
    ),
    PathEvent(
      title: 'Crew at the Breaking Point',
      flavor: 'After the gauntlet, your crew sits in silence. One of them says: "We made it." Nobody argues.',
      type: PathEventType.intel,
      fearDelta: -8,
      loyaltyDelta: 5,
    ),
  ],

  'accordprime-vanguard': [
    PathEvent(
      title: 'Escort Wing Recalled',
      flavor: 'Your escort breaks formation on new orders. You are told nothing. The comms go silent.',
      type: PathEventType.hazard,
      fearDelta: 8,
    ),
    PathEvent(
      title: 'Priority Command Channel',
      flavor: 'Accord Command broadcasts directly to your bridge. The message is clear: arrive clean. Arrive correct.',
      type: PathEventType.intel,
      fearDelta: 4,
      loyaltyDelta: -3,
    ),
    PathEvent(
      title: 'Final Security Levy',
      flavor: 'Automated Accord tollgate. Credits deducted without authorization. The receipt says "processing fee."',
      type: PathEventType.hazard,
      creditsDelta: -20,
    ),
  ],

  'accordprime-solune': [
    PathEvent(
      title: 'The Long Empty Burn',
      flavor: 'Forty hours through open space with no navigational landmarks. Every system nominal. Crew stress is not.',
      type: PathEventType.hazard,
      oxygenDelta: -10,
      fuelDelta: -8,
      fearDelta: 7,
    ),
    PathEvent(
      title: 'Phantom Contact',
      flavor: 'An unknown vessel appears on sensors for six minutes then vanishes. No transponder. No comm response. Nothing.',
      type: PathEventType.intel,
      fearDelta: 12,
    ),
    PathEvent(
      title: 'Chithari Flanker',
      flavor: 'A lone alien ship — fast, silent, furious — attacks without warning. You bring it down. The damage is done.',
      type: PathEventType.hazard,
      hullDelta: -20,
      ammoDelta: -15,
      fearDelta: 10,
      oxygenDelta: -5,
    ),
  ],
};
