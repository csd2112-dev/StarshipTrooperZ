import 'dart:math';
import '../models/game_state.dart';
import '../models/encounter.dart';
import '../data/encounters.dart';

class EncounterEngine {
  static final Random _rng = Random();

  /// Pick an appropriate encounter for the current game state,
  /// avoiding encounters already played this run.
  static EncounterData? pick(GameState gs, Set<String> played) {
    final available = encounterPool.where((e) {
      if (played.contains(e.id)) return false;
      if (gs.sector < e.minSector || gs.sector > e.maxSector) return false;
      if (e.minBugSympathy > 0 &&
          gs.psychology.bugSympathy < e.minBugSympathy) {
        return false;
      }
      return true;
    }).toList();

    if (available.isEmpty) return null;
    available.shuffle(_rng);
    return available.first;
  }

  /// Apply a choice's full consequences to the game state.
  static void apply(GameState gs, EncounterChoice choice) {
    // Ship resources
    gs.hull = (gs.hull + choice.hullDelta).clamp(0, gs.maxHull);
    gs.fuel = (gs.fuel + choice.fuelDelta).clamp(0, gs.maxFuel);
    gs.rations = (gs.rations + choice.rationsDelta).clamp(0, gs.maxRations);
    gs.oxygen = (gs.oxygen + choice.oxygenDelta).clamp(0, gs.maxOxygen);
    gs.ammo = (gs.ammo + choice.ammoDelta).clamp(0, 100);
    gs.medicine = (gs.medicine + choice.medicineDelta).clamp(0, 100);
    gs.salvage = (gs.salvage + choice.salvageDelta).clamp(0, 999);
    gs.credits = (gs.credits + choice.creditsDelta).clamp(0, 9999);

    // Block a route if this choice causes one
    if (choice.blocksConnection != null) {
      gs.blockedConnections.add(choice.blocksConnection!);
      gs.addLog('ROUTE BLOCKED: ${choice.blocksConnection!.replaceAll('-', ' — ').toUpperCase()}');
    }

    // Crew psychology
    for (final c in gs.crew.where((c) => c.isAlive)) {
      final statusBonus = c.status == CrewStatus.citizen
          ? choice.citizenLoyaltyDelta
          : choice.civilianLoyaltyDelta;
      c.loyalty =
          (c.loyalty + choice.loyaltyDelta + statusBonus).clamp(0, 100);
      c.fear = (c.fear + choice.fearDelta).clamp(0, 100);
      c.hope = (c.hope + choice.hopeDelta).clamp(0, 100);
    }

    // Commander psychology
    gs.psychology.resolve =
        (gs.psychology.resolve + choice.resolveDelta).clamp(0, 100);
    gs.psychology.empathy =
        (gs.psychology.empathy + choice.empathyDelta).clamp(0, 100);
    gs.psychology.authority =
        (gs.psychology.authority + choice.authorityDelta).clamp(0, 100);
    gs.psychology.bugSympathy =
        (gs.psychology.bugSympathy + choice.bugSympathyDelta).clamp(0, 100);
    gs.psychology.reputation =
        (gs.psychology.reputation + choice.reputationDelta).clamp(-100, 100);

    // Order / tension
    gs.civilianTension =
        (gs.civilianTension + choice.civilianTensionDelta).clamp(0, 100);
    gs.orderLevel = (gs.orderLevel + choice.orderDelta).clamp(0, 100);

    // Alien knowledge
    for (final entry in choice.alienKnowledgeDelta.entries) {
      final current = gs.alienKnowledge[entry.key] ?? 0;
      gs.alienKnowledge[entry.key] = (current + entry.value).clamp(0, 100);
    }

    // Tension cascade
    if (gs.civilianTension >= 80) {
      gs.orderLevel = (gs.orderLevel - 10).clamp(0, 100);
      gs.addLog('WARNING: Civilian tension critical — order declining.');
    }

    _checkVitals(gs);
  }

  /// Deduct per-node-jump running costs and check vitals.
  static void applyJumpCost(GameState gs) {
    gs.fuel = (gs.fuel - 5).clamp(0, gs.maxFuel);
    gs.oxygen = (gs.oxygen - 5).clamp(0, gs.maxOxygen);
    gs.rations = (gs.rations - 3).clamp(0, gs.maxRations);
    _checkVitals(gs);
  }

  /// Advance the sector and apply hyperspace transit costs.
  static void advanceSector(GameState gs) {
    gs.sector++;
    gs.day += 3;

    // Reduced transit decay (per-jump costs now cover most attrition)
    gs.fuel = (gs.fuel - 8).clamp(0, gs.maxFuel);
    gs.rations = (gs.rations - 4).clamp(0, gs.maxRations);

    // Crew morale drift
    final tensionEffect = gs.civilianTension > 60 ? -5 : 0;
    final quartersBonus = gs.upgrades.crewQuarters * 2;
    for (final c in gs.crew.where((c) => c.isAlive)) {
      c.hope = (c.hope - 3 + quartersBonus + tensionEffect).clamp(0, 100);
    }

    // Med bay reduces trauma passively
    if (gs.upgrades.medBay > 0) {
      for (final c in gs.crew.where((c) => c.isAlive && c.trauma > 0)) {
        c.trauma = (c.trauma - gs.upgrades.medBay * 3).clamp(0, 100);
      }
    }

    gs.addLog(
        'Sector ${gs.sector - 1} cleared. Jump initiated — Sector ${gs.sector}.');

    if (gs.sector > 5) {
      gs.isGameOver = true;
      gs.endingType = _computeEnding(gs);
      gs.gameOverReason = 'Mission complete.';
      return;
    }

    _checkVitals(gs);
  }

  static void _checkVitals(GameState gs) {
    if (gs.isGameOver) return;
    if (gs.hull <= 0) {
      gs.isGameOver = true;
      gs.gameOverReason = 'Hull integrity lost. The ship did not survive.';
    } else if (gs.oxygen <= 0) {
      gs.isGameOver = true;
      gs.gameOverReason =
          'Life support failure. Oxygen reserves depleted. The crew is gone.';
    } else if (gs.rations <= 0) {
      gs.isGameOver = true;
      gs.gameOverReason =
          'Crew starved. Rations exhausted before reaching Accord Prime.';
    } else if (gs.fuel <= 0) {
      gs.isGameOver = true;
      gs.gameOverReason =
          'Engines offline. Fuel reserves depleted. Ship adrift.';
    } else if (gs.civilianTension >= 100) {
      gs.isGameOver = true;
      gs.gameOverReason =
          'Civilian uprising. The crew took control of the ship.';
    } else if (gs.avgLoyalty < 15) {
      gs.isGameOver = true;
      gs.gameOverReason =
          'Crew mutiny. You lost the ship before you lost the war.';
    }
  }

  static String _computeEnding(GameState gs) {
    if (gs.psychology.bugSympathy >= 60) return 'the_truth';
    if (gs.psychology.reputation >= 40) return 'accord_hero';
    return 'roughneck_legend';
  }
}
