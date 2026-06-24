// ─── Enums ────────────────────────────────────────────────────────────────────

enum PlayerBackground {
  vanguardConscript,
  civicOfficer,
  medtechSpecialist,
  xenodataAnalyst,
}

extension PlayerBackgroundInfo on PlayerBackground {
  String get displayName => switch (this) {
    PlayerBackground.vanguardConscript => 'Vanguard Conscript',
    PlayerBackground.civicOfficer => 'Civic Officer',
    PlayerBackground.medtechSpecialist => 'Medtech Specialist',
    PlayerBackground.xenodataAnalyst => 'Xenodata Analyst',
  };

  String get description => switch (this) {
    PlayerBackground.vanguardConscript =>
      'Front-line mobile infantry. High resolve and authority. Crew fears and respects you.',
    PlayerBackground.civicOfficer =>
      'Political attaché from the Accord. Strong command presence but crew distrust is baked in from day one.',
    PlayerBackground.medtechSpecialist =>
      'Field surgeon with xenobiology training. Deep crew empathy. Morale events hit harder — for better or worse.',
    PlayerBackground.xenodataAnalyst =>
      'Intelligence operative. You know more about alien species than the Accord wants you to. Bonus knowledge from the start.',
  };

  List<String> get statBonuses => switch (this) {
    PlayerBackground.vanguardConscript => [
      '+20 Resolve',
      '+10 Authority',
      '+15 Ammo',
    ],
    PlayerBackground.civicOfficer => [
      '+25 Authority',
      '+10 Order Level',
      '−10 Empathy',
    ],
    PlayerBackground.medtechSpecialist => [
      '+25 Empathy',
      '+20 Medicine',
      '−5 Resolve',
    ],
    PlayerBackground.xenodataAnalyst => [
      '+15 Alien Knowledge (all)',
      '+10 Empathy',
      '+5 Salvage',
    ],
  };
}

enum StartingPort { vektaraStation, dustholdOutpost, kavethTransit }

extension StartingPortInfo on StartingPort {
  String get displayName => switch (this) {
    StartingPort.vektaraStation => 'Vektara Station',
    StartingPort.dustholdOutpost => 'Dusthold Outpost',
    StartingPort.kavethTransit => 'New Kaveth Transit',
  };

  String get subtitle => switch (this) {
    StartingPort.vektaraStation => 'Inner System — Orbital Hub',
    StartingPort.dustholdOutpost => 'Outer Belt — Frontier Base',
    StartingPort.kavethTransit => 'Fringe — Evacuation Port',
  };

  String get description => switch (this) {
    StartingPort.vektaraStation =>
      'Well-supplied orbital transit hub. Heavily monitored by the Civic Accord. Mostly citizens on crew — discipline is high, but so is the propaganda.',
    StartingPort.dustholdOutpost =>
      'Scarce supplies, battle-hardened personnel, and a cache of salvage from the last skirmish. Hull took some hits. Nobody here trusts the Accord.',
    StartingPort.kavethTransit =>
      'Former civilian evacuation port. Mixed crew with existing tension between citizens and civilians. Medical supplies are plentiful. Order is fragile.',
  };

  List<String> get conditions => switch (this) {
    StartingPort.vektaraStation => ['Fuel 90%', 'Rations 80%', '+5 Order'],
    StartingPort.dustholdOutpost => [
      'Hull 65%',
      'Fuel 55%',
      '+20 Ammo',
      '+8 Salvage',
    ],
    StartingPort.kavethTransit => [
      'Rations 45%',
      'Tension: 40',
      '+10 Medicine',
    ],
  };
}

enum CrewStatus { citizen, civilian }

enum AlienSpecies { chithari, vyrathi, kethAri, solune }

extension AlienSpeciesInfo on AlienSpecies {
  String get displayName => switch (this) {
    AlienSpecies.chithari => 'Chithari',
    AlienSpecies.vyrathi => 'Vyrathi',
    AlienSpecies.kethAri => "Keth'ari",
    AlienSpecies.solune => 'Solune',
  };

  String get briefing => switch (this) {
    AlienSpecies.chithari =>
      'Insectoid swarm species. Official Accord position: mindless hostiles. Something about that doesn\'t add up.',
    AlienSpecies.vyrathi =>
      'Ancient crystalline entities. Appear to communicate through resonance fields. Motivations unknown.',
    AlienSpecies.kethAri =>
      'Nomadic warrior clans. Respect is earned through demonstrated strength. Diplomacy is a form of combat to them.',
    AlienSpecies.solune =>
      'Advanced traders and mediators. Will engage diplomatically — for a price. Their morality is purely transactional.',
  };
}

// ─── Crew ─────────────────────────────────────────────────────────────────────

enum CrewDuty { security, navigation, medical, engineering, intelligence }

extension CrewDutyInfo on CrewDuty {
  String get label => switch (this) {
    CrewDuty.security     => 'Security',
    CrewDuty.navigation   => 'Navigation',
    CrewDuty.medical      => 'Medical',
    CrewDuty.engineering  => 'Engineering',
    CrewDuty.intelligence => 'Intelligence',
  };
  String get description => switch (this) {
    CrewDuty.security     => 'Standing guard. Reduces tension by 3 per sector.',
    CrewDuty.navigation   => 'Plotting safest routes. Saves 2 fuel per jump.',
    CrewDuty.medical      => 'Monitoring crew health. Heals 4 trauma per sector.',
    CrewDuty.engineering  => 'Maintaining systems. Repairs 3 hull per sector.',
    CrewDuty.intelligence => 'Monitoring comms. Grants +5 alien knowledge per sector.',
  };
}

class CrewMember {
  String name;
  String role;
  CrewStatus status;
  int loyalty; // 0–100
  int fear; // 0–100
  int hope; // 0–100
  int trauma; // 0–100, accumulates permanently
  int combatSkill;
  int techSkill;
  int medicalSkill;
  int diplomaticSkill;
  int alienKnowledge;
  bool isAlive;
  List<String> traumaEvents;
  CrewDuty? assignedDuty;
  bool interactedThisSector;

  CrewMember({
    required this.name,
    required this.role,
    required this.status,
    this.loyalty = 60,
    this.fear = 20,
    this.hope = 70,
    this.trauma = 0,
    this.combatSkill = 30,
    this.techSkill = 30,
    this.medicalSkill = 30,
    this.diplomaticSkill = 30,
    this.alienKnowledge = 10,
    this.isAlive = true,
    this.assignedDuty,
    this.interactedThisSector = false,
    List<String>? traumaEvents,
  }) : traumaEvents = traumaEvents ?? [];

  String get statusLabel =>
      status == CrewStatus.citizen ? 'CITIZEN' : 'CIVILIAN';

  String get loyaltyLabel {
    if (loyalty >= 80) return 'Devoted';
    if (loyalty >= 60) return 'Loyal';
    if (loyalty >= 40) return 'Uneasy';
    if (loyalty >= 20) return 'Resentful';
    return 'Mutinous';
  }

  String get talkLine {
    if (loyalty >= 80) return '"Commander. I\'d follow you to the end of the sector."';
    if (loyalty >= 60) return '"You can count on me, sir. Always."';
    if (loyalty >= 40) return '"I\'m... doing my best out here. That\'s all I can say."';
    if (loyalty >= 20) return '"What do you want? I\'m busy."';
    return '"Don\'t push me right now, Commander."';
  }
}

// ─── Ship ─────────────────────────────────────────────────────────────────────

class ShipUpgrades {
  int hullPlating; // 0–3: reduces hull damage per event
  int driveCore; // 0–3: fuel efficiency
  int medBay; // 0–3: trauma recovery rate
  int crewQuarters; // 0–3: passive morale regeneration
  int weaponsArray; // 0–3: combat outcome boost
  int researchTerminal; // 0–3: alien knowledge gain speed

  ShipUpgrades({
    this.hullPlating = 0,
    this.driveCore = 0,
    this.medBay = 0,
    this.crewQuarters = 0,
    this.weaponsArray = 0,
    this.researchTerminal = 0,
  });

  int get total =>
      hullPlating +
      driveCore +
      medBay +
      crewQuarters +
      weaponsArray +
      researchTerminal;

  String nameOf(int index) => [
    'Hull Plating',
    'Drive Core',
    'Med Bay',
    'Crew Quarters',
    'Weapons Array',
    'Research Terminal',
  ][index];

  int levelOf(int index) => [
    hullPlating,
    driveCore,
    medBay,
    crewQuarters,
    weaponsArray,
    researchTerminal,
  ][index];
}

// ─── Psychology ───────────────────────────────────────────────────────────────

class PsychologyProfile {
  int resolve; // 0–100: capacity for hard decisions without breaking
  int empathy; // 0–100: how crew bonds respond to your actions
  int authority; // 0–100: command presence — affects civilian compliance
  int bugSympathy; // 0–100: HIDDEN — sensing Chithari intelligence
  int reputation; // −100 to 100: Civic Accord standing

  PsychologyProfile({
    this.resolve = 50,
    this.empathy = 50,
    this.authority = 50,
    this.bugSympathy = 0,
    this.reputation = 0,
  });

  String get resolveLabel {
    if (resolve >= 80) return 'Ironclad';
    if (resolve >= 60) return 'Steady';
    if (resolve >= 40) return 'Wavering';
    if (resolve >= 20) return 'Cracking';
    return 'Broken';
  }

  String get reputationLabel {
    if (reputation >= 60) return 'Accord Hero';
    if (reputation >= 20) return 'Reliable Asset';
    if (reputation >= -20) return 'Under Scrutiny';
    if (reputation >= -60) return 'Person of Interest';
    return 'Wanted';
  }
}

// ─── Game State ───────────────────────────────────────────────────────────────

class GameState {
  String commanderName;
  PlayerBackground background;
  StartingPort startingPort;

  int sector; // 1–5
  int day;

  // Ship resources (0–100 or raw int)
  int hull;
  final int maxHull = 100;
  int fuel;
  final int maxFuel = 100;
  int rations;
  final int maxRations = 100;
  int oxygen;
  final int maxOxygen = 100;
  int ammo;
  int medicine;
  int salvage;
  int credits;
  Set<String> blockedConnections;

  // Social order
  int civilianTension; // 0–100: risk of civilian unrest
  int orderLevel; // 0–100: overall command discipline

  // Alien contact progress per species
  Map<AlienSpecies, int> alienKnowledge;

  ShipUpgrades upgrades;
  PsychologyProfile psychology;
  List<CrewMember> crew;
  List<String> missionLog;

  bool isGameOver;
  String? gameOverReason;
  String? endingType; // 'accord_hero' | 'roughneck_legend' | 'the_truth'

  GameState({
    required this.commanderName,
    required this.background,
    required this.startingPort,
  }) : sector = 1,
       day = 1,
       hull = 80,
       fuel = 75,
       rations = 60,
       oxygen = 100,
       ammo = 50,
       medicine = 40,
       salvage = 0,
       credits = 50,
       blockedConnections = <String>{},
       civilianTension = 20,
       orderLevel = 80,
       alienKnowledge = {for (final s in AlienSpecies.values) s: 5},
       upgrades = ShipUpgrades(),
       psychology = PsychologyProfile(),
       crew = [],
       missionLog = [],
       isGameOver = false {
    _applyBackground();
    _applyPort();
    _generateCrew();
    addLog('Mission initiated. Departing ${startingPort.displayName}.');
  }

  void _applyBackground() {
    switch (background) {
      case PlayerBackground.vanguardConscript:
        psychology.resolve = (psychology.resolve + 20).clamp(0, 100);
        psychology.authority = (psychology.authority + 10).clamp(0, 100);
        ammo += 15;
        credits += 10;
      case PlayerBackground.civicOfficer:
        psychology.authority = (psychology.authority + 25).clamp(0, 100);
        psychology.empathy = (psychology.empathy - 10).clamp(0, 100);
        orderLevel = (orderLevel + 10).clamp(0, 100);
        credits += 30;
      case PlayerBackground.medtechSpecialist:
        psychology.empathy = (psychology.empathy + 25).clamp(0, 100);
        medicine += 20;
        psychology.resolve = (psychology.resolve - 5).clamp(0, 100);
        credits += 5;
      case PlayerBackground.xenodataAnalyst:
        for (final s in AlienSpecies.values) {
          alienKnowledge[s] = 20;
        }
        psychology.empathy = (psychology.empathy + 10).clamp(0, 100);
        salvage += 5;
    }
  }

  void _applyPort() {
    switch (startingPort) {
      case StartingPort.vektaraStation:
        fuel = 90;
        rations = 80;
        orderLevel = (orderLevel + 5).clamp(0, 100);
      case StartingPort.dustholdOutpost:
        hull = 65;
        fuel = 55;
        ammo += 20;
        salvage += 8;
        psychology.resolve = (psychology.resolve + 10).clamp(0, 100);
      case StartingPort.kavethTransit:
        rations = 45;
        civilianTension = 40;
        medicine += 10;
    }
  }

  void _generateCrew() {
    crew = [
      CrewMember(
        name: 'Sgt. Varro',
        role: 'Combat Lead',
        status: CrewStatus.citizen,
        combatSkill: 75,
        loyalty: 65,
        fear: 15,
        hope: 60,
      ),
      CrewMember(
        name: 'Dr. Yessa',
        role: 'Field Medic',
        status: CrewStatus.civilian,
        medicalSkill: 80,
        diplomaticSkill: 50,
        loyalty: 55,
        fear: 25,
        hope: 80,
      ),
      CrewMember(
        name: 'Pvt. Drex',
        role: 'Engineer',
        status: CrewStatus.civilian,
        techSkill: 65,
        loyalty: 50,
        fear: 35,
        hope: 55,
      ),
      CrewMember(
        name: 'Cpl. Maren',
        role: 'Navigator',
        status: CrewStatus.citizen,
        techSkill: 55,
        diplomaticSkill: 45,
        loyalty: 70,
        fear: 20,
        hope: 70,
      ),
      CrewMember(
        name: 'Zhen',
        role: 'Xeno-Analyst',
        status: CrewStatus.civilian,
        alienKnowledge: 35,
        diplomaticSkill: 60,
        loyalty: 45,
        fear: 30,
        hope: 85,
      ),
    ];
  }

  // ─── Computed ────────────────────────────────────────────────────────────────

  int get citizenCount =>
      crew.where((c) => c.status == CrewStatus.citizen && c.isAlive).length;
  int get civilianCount =>
      crew.where((c) => c.status == CrewStatus.civilian && c.isAlive).length;
  int get aliveCount => crew.where((c) => c.isAlive).length;

  double get avgLoyalty {
    final alive = crew.where((c) => c.isAlive).toList();
    if (alive.isEmpty) return 0;
    return alive.map((c) => c.loyalty).reduce((a, b) => a + b) / alive.length;
  }

  double get avgFear {
    final alive = crew.where((c) => c.isAlive).toList();
    if (alive.isEmpty) return 0;
    return alive.map((c) => c.fear).reduce((a, b) => a + b) / alive.length;
  }

  String get tensionLabel {
    if (civilianTension < 25) return 'STABLE';
    if (civilianTension < 50) return 'UNEASY';
    if (civilianTension < 75) return 'VOLATILE';
    return 'CRITICAL';
  }

  void addLog(String entry) {
    missionLog.insert(0, entry);
    if (missionLog.length > 40) missionLog.removeLast();
  }

  void resetSectorInteractions() {
    for (final c in crew) {
      c.interactedThisSector = false;
    }
  }

  // Apply passive duty bonuses for all living crew at sector end
  void applyDutyBonuses() {
    for (final c in crew.where((c) => c.isAlive && c.assignedDuty != null)) {
      switch (c.assignedDuty!) {
        case CrewDuty.security:
          civilianTension = (civilianTension - 3).clamp(0, 100);
        case CrewDuty.navigation:
          fuel = (fuel + 2).clamp(0, maxFuel);
        case CrewDuty.medical:
          c.trauma = (c.trauma - 4).clamp(0, 100);
        case CrewDuty.engineering:
          hull = (hull + 3).clamp(0, maxHull);
        case CrewDuty.intelligence:
          for (final s in AlienSpecies.values) {
            alienKnowledge[s] = ((alienKnowledge[s] ?? 0) + 5).clamp(0, 100);
          }
      }
    }
  }

  // ─── Route Management ────────────────────────────────────────────────────────

  static String connectionKey(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}-${pair[1]}';
  }

  bool isConnectionBlocked(String a, String b) =>
      blockedConnections.contains(connectionKey(a, b));

  void blockConnection(String a, String b) {
    blockedConnections.add(connectionKey(a, b));
    addLog('WARNING: Route ${a.toUpperCase()} — ${b.toUpperCase()} is now blocked.');
  }

  // Credit cost to upgrade from current level to next (tier 1=25, 2=50, 3=100)
  static int upgradeCost(int currentLevel) => switch (currentLevel) {
    0 => 25,
    1 => 50,
    _ => 100,
  };

  // Spend credits to purchase an upgrade; returns true if successful
  bool purchaseUpgrade(String upgradeKey) {
    final lvl = switch (upgradeKey) {
      'hull'     => upgrades.hullPlating,
      'drive'    => upgrades.driveCore,
      'med'      => upgrades.medBay,
      'quarters' => upgrades.crewQuarters,
      'weapons'  => upgrades.weaponsArray,
      'research' => upgrades.researchTerminal,
      _          => 3, // unknown key — block purchase
    };
    if (lvl >= 3) return false;
    final cost = upgradeCost(lvl);
    if (credits < cost) return false;
    credits -= cost;
    switch (upgradeKey) {
      case 'hull':     upgrades.hullPlating++;
      case 'drive':    upgrades.driveCore++;
      case 'med':      upgrades.medBay++;
      case 'quarters': upgrades.crewQuarters++;
      case 'weapons':  upgrades.weaponsArray++;
      case 'research': upgrades.researchTerminal++;
    }
    addLog('Research complete: ${upgrades.nameOf(['hull','drive','med','quarters','weapons','research'].indexOf(upgradeKey))} Mk.${lvl + 1}.');
    return true;
  }
}
