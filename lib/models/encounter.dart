import 'package:flutter/material.dart';
import 'game_state.dart';

class EncounterChoice {
  final String label;
  final String sub;
  final String outcome;
  final Color color;

  // Ship resources
  final int hullDelta;
  final int fuelDelta;
  final int rationsDelta;
  final int ammoDelta;
  final int medicineDelta;
  final int salvageDelta;

  // Crew psychology (applied to all living crew)
  final int loyaltyDelta;
  final int citizenLoyaltyDelta;   // bonus for citizens only
  final int civilianLoyaltyDelta;  // bonus for civilians only
  final int fearDelta;
  final int hopeDelta;

  // Commander psychology
  final int resolveDelta;
  final int empathyDelta;
  final int authorityDelta;
  final int bugSympathyDelta;  // hidden
  final int reputationDelta;

  // Order system
  final int civilianTensionDelta;
  final int orderDelta;

  // Alien knowledge
  final Map<AlienSpecies, int> alienKnowledgeDelta;

  // Economy & routes
  final int creditsDelta;
  final int oxygenDelta;
  final String? blocksConnection; // sorted pair e.g. "graveyard-kethreach"

  const EncounterChoice({
    required this.label,
    required this.sub,
    required this.outcome,
    this.color = const Color(0xFF00FF88),
    this.hullDelta = 0,
    this.fuelDelta = 0,
    this.rationsDelta = 0,
    this.ammoDelta = 0,
    this.medicineDelta = 0,
    this.salvageDelta = 0,
    this.loyaltyDelta = 0,
    this.citizenLoyaltyDelta = 0,
    this.civilianLoyaltyDelta = 0,
    this.fearDelta = 0,
    this.hopeDelta = 0,
    this.resolveDelta = 0,
    this.empathyDelta = 0,
    this.authorityDelta = 0,
    this.bugSympathyDelta = 0,
    this.reputationDelta = 0,
    this.civilianTensionDelta = 0,
    this.orderDelta = 0,
    this.alienKnowledgeDelta = const {},
    this.creditsDelta = 0,
    this.oxygenDelta = 0,
    this.blocksConnection,
  });
}

class EncounterData {
  final String id;
  final String title;
  final String sectorTag;   // shown at top of dialog e.g. "SECTOR 1 — DEBRIS FIELD"
  final String story;
  final List<EncounterChoice> choices;
  final int minSector;
  final int maxSector;
  final int minBugSympathy;  // only unlocked when hidden stat reaches threshold

  const EncounterData({
    required this.id,
    required this.title,
    required this.sectorTag,
    required this.story,
    required this.choices,
    this.minSector = 1,
    this.maxSector = 5,
    this.minBugSympathy = 0,
  });
}
