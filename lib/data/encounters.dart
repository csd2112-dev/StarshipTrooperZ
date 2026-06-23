import 'package:flutter/material.dart';
import '../models/encounter.dart';
import '../models/game_state.dart';

// ─── Full encounter pool — all sectors ────────────────────────────────────────
// Sector tags: 1=early, 2-3=mid, 4-5=late. Each encounter has min/maxSector.

const List<EncounterData> encounterPool = [

  // ── SECTOR 1 ───────────────────────────────────────────────────────────────

  EncounterData(
    id: 'distress_signal',
    title: 'DISTRESS SIGNAL',
    sectorTag: 'SECTOR 1  —  DEBRIS FIELD',
    minSector: 1, maxSector: 2,
    story:
        'Long-range sensors lock onto a civilian transport drifting in the debris field ahead. '
        'Life signs confirm survivors — a mix of citizens and civilians. '
        'The distress signal has been looping for six hours.\n\n'
        'Your navigator flags it: "Commander, nobody sends a manual distress that long without checking in. '
        'Either they can\'t respond — or something is doing it for them."',
    choices: [
      EncounterChoice(
        label: 'BOARD THE TRANSPORT',
        sub: 'Risk hull exposure in the debris field. Crew morale improves if survivors are found.',
        color: Color(0xFF00FF88),
        hullDelta: -5,
        loyaltyDelta: 8,
        hopeDelta: 5,
        bugSympathyDelta: 5,
        creditsDelta: 20,
        alienKnowledgeDelta: {AlienSpecies.chithari: 8},
        outcome:
            'You docked and boarded. The survivors were real — twenty-three of them. '
            'A Chithari scouting probe had been mimicking their signal, waiting for a ship to come close. '
            'Your boarding team identified and destroyed it before it could report your position. '
            'The hull took scrapes. Dr. Yessa worked through the night. '
            'Nobody said much, but the crew watched you differently after.',
      ),
      EncounterChoice(
        label: 'BROADCAST REPLY — WAIT FOR RESPONSE',
        sub: 'Cautious approach. No resource risk, but the signal cuts off.',
        color: Color(0xFF00AAFF),
        loyaltyDelta: -4,
        fearDelta: 5,
        alienKnowledgeDelta: {AlienSpecies.chithari: 4},
        outcome:
            'You responded on their frequency. '
            'The signal cut off immediately. No contact. No survivors located. '
            'Whether they got out or the probe moved on — you will never know. '
            'The crew is unsettled. Zhen logged it without comment.',
      ),
      EncounterChoice(
        label: 'MAINTAIN HEADING — IGNORE THE SIGNAL',
        sub: 'Mission efficiency preserved. Civilian crew members will remember this decision.',
        color: Color(0xFFFF8844),
        loyaltyDelta: -8,
        civilianLoyaltyDelta: -8,
        fearDelta: 3,
        civilianTensionDelta: 15,
        empathyDelta: -3,
        resolveDelta: 2,
        outcome:
            'You ordered the ship forward. Sgt. Varro said nothing. '
            'Dr. Yessa did not speak to you at dinner. '
            'Zhen logged the signal in the comms record without comment. '
            'The mission stays on schedule. '
            'The crew now knows who you are.',
      ),
    ],
  ),

  EncounterData(
    id: 'rationing_dispute',
    title: 'THE RATION QUESTION',
    sectorTag: 'SECTOR 1  —  TRANSIT CORRIDOR',
    minSector: 1, maxSector: 3,
    story:
        'Rations are running lower than projected, and the civilian section of the crew has begun organizing. '
        'Dr. Yessa comes to you before it becomes a confrontation.\n\n'
        '"Commander, they\'re not making demands — not yet. Citizens are taking priority at meals. '
        'It\'s regulation, I know. But the math doesn\'t hold at our current rate. '
        'Something changes before we reach Sector 3, or they change it themselves."',
    choices: [
      EncounterChoice(
        label: 'EQUAL RATIONS FOR ALL',
        sub: 'Breaks citizen priority protocol. Civilian morale rises. Citizen loyalty drops.',
        color: Color(0xFF00FF88),
        civilianLoyaltyDelta: 12,
        citizenLoyaltyDelta: -7,
        authorityDelta: -5,
        empathyDelta: 5,
        civilianTensionDelta: -18,
        reputationDelta: -5,
        outcome:
            'You cancelled the citizen meal priority protocol. '
            'The civilian crew ate with everyone else for the first time since departure. '
            'Dr. Yessa thanked you quietly. Sgt. Varro said nothing at dinner, which meant something. '
            'The Accord would not approve of this. That\'s probably why it felt right.',
      ),
      EncounterChoice(
        label: 'MAINTAIN CITIZEN PRIORITY — THIS IS PROTOCOL',
        sub: 'Order is maintained. Civilian resentment compounds.',
        color: Color(0xFFFF8844),
        citizenLoyaltyDelta: 8,
        civilianLoyaltyDelta: -12,
        authorityDelta: 5,
        civilianTensionDelta: 25,
        orderDelta: 5,
        reputationDelta: 5,
        outcome:
            'Protocol stands. Citizens eat first. Civilians eat what\'s left. '
            'Order is maintained — on paper. '
            'Zhen stopped meeting your eyes at briefings. '
            'Pvt. Drex fixed a critical fuel line that afternoon and didn\'t report it. '
            'You found out three days later.',
      ),
      EncounterChoice(
        label: 'IMPLEMENT STRICT UNIVERSAL RATION CONTROL',
        sub: 'Eliminates the problem by eliminating preference entirely. Everyone loses something.',
        color: Color(0xFF00AAFF),
        loyaltyDelta: -5,
        fearDelta: 8,
        hopeDelta: -5,
        orderDelta: 12,
        resolveDelta: 3,
        civilianTensionDelta: -5,
        outcome:
            'You locked the ration system and enforced equal reduced portions across all crew regardless of status. '
            'Nobody argued. Nobody thanked you. '
            'The numbers stabilized. '
            'The silence at meals lasted two weeks.',
      ),
    ],
  ),

  EncounterData(
    id: 'chithari_observer',
    title: 'THE OBSERVER',
    sectorTag: 'SECTOR 1  —  ASTEROID BELT ZETA-9',
    minSector: 1, maxSector: 3,
    story:
        'Zhen calls you to the sensor bay, voice quieter than usual. On the display: '
        'a lone Chithari drone moving in a precise, repeating grid pattern through the asteroid field. '
        'It has not registered your ship.\n\n'
        '"It\'s not hunting," Zhen says slowly. '
        '"Look at the movement — it\'s cataloguing. Mineral composition, structural density. '
        'It\'s been running this grid for six hours." '
        'She pauses. "Commander. Chithari don\'t catalogue. They don\'t study things."',
    choices: [
      EncounterChoice(
        label: 'DESTROY IT',
        sub: 'By the book. No risk, no questions. Crew expects this.',
        color: Color(0xFFFF8844),
        ammoDelta: -10,
        loyaltyDelta: 3,
        citizenLoyaltyDelta: 5,
        bugSympathyDelta: -8,
        creditsDelta: 15,
        alienKnowledgeDelta: {AlienSpecies.chithari: 5},
        outcome:
            'You destroyed the drone with a single precision burst. '
            'Sgt. Varro gave a short nod. Zhen watched the debris scatter for a long time. '
            'Whatever it was cataloguing, it\'s gone now. '
            'That should feel like the right outcome.',
      ),
      EncounterChoice(
        label: 'OBSERVE IN COMPLETE SILENCE',
        sub: 'Full sensor recording. No engagement. Unsettling but informative.',
        color: Color(0xFF00AAFF),
        fearDelta: 5,
        resolveDelta: -2,
        bugSympathyDelta: 15,
        alienKnowledgeDelta: {AlienSpecies.chithari: 20},
        outcome:
            'You watched for four hours. The drone completed its grid, paused — '
            'and then performed a second pass of three specific asteroids it had already logged. '
            'It was verifying. Checking its own work. '
            'Zhen transcribed everything. Neither of you said what you were both thinking.',
      ),
      EncounterChoice(
        label: 'ATTEMPT TO SIGNAL IT',
        sub: 'Unauthorized first contact. High risk. Changes everything if it works.',
        color: Color(0xFF00FF88),
        fuelDelta: -5,
        fearDelta: 12,
        reputationDelta: -15,
        bugSympathyDelta: 25,
        alienKnowledgeDelta: {AlienSpecies.chithari: 28},
        outcome:
            'You transmitted on the drone\'s operational frequency — a simple geometric sequence, '
            'the kind that crosses language. '
            'The drone stopped. Held position for eleven seconds. '
            'Then it left. Fast. Not the scatter of a startled machine. '
            'The purposeful withdrawal of something that had somewhere to be. '
            'The crew does not speak of this. Neither does the mission log.',
      ),
    ],
  ),

  EncounterData(
    id: 'accord_diversion',
    title: 'TIER-1 DISPATCH',
    sectorTag: 'SECTOR 1  —  COMMS LOG',
    minSector: 1, maxSector: 4,
    story:
        'A priority AccordNet message arrives — Tier-1 clearance, fully encrypted. '
        'The order: divert course to extract an embedded Accord propagandist from a civilian freighter. '
        'The diversion adds three days and burns fuel you cannot afford to lose. '
        'The order is marked non-negotiable.\n\n'
        'Sgt. Varro reads it over your shoulder. Says nothing. '
        'Zhen looks at her console. None of them have to say what they\'re thinking.',
    choices: [
      EncounterChoice(
        label: 'COMPLY WITHOUT COMMENT',
        sub: 'Accord standing improves. Crew loyalty drops. Fuel cost is significant.',
        color: Color(0xFF00AAFF),
        fuelDelta: -20,
        loyaltyDelta: -8,
        hopeDelta: -5,
        orderDelta: 5,
        reputationDelta: 15,
        creditsDelta: 30,
        outcome:
            'You changed course and made the extraction. '
            'The propagandist said very little. Smiled a lot. '
            'Your crew watched them board and then went back to their stations without speaking. '
            'The Accord logged the mission as completed satisfactorily. '
            'The crew logged nothing. They didn\'t need to.',
      ),
      EncounterChoice(
        label: 'COMPLY — LOG FORMAL OBJECTION',
        sub: 'You follow orders but put your name on the disagreement.',
        color: Color(0xFF00FF88),
        fuelDelta: -20,
        loyaltyDelta: -3,
        resolveDelta: 2,
        reputationDelta: 5,
        creditsDelta: 30,
        outcome:
            'You complied and logged a formal operational objection citing fuel reserves and mission risk. '
            'The Accord acknowledged receipt. '
            'The crew saw you write it. '
            'Zhen printed a copy and kept it.',
      ),
      EncounterChoice(
        label: 'IGNORE THE ORDER — MAINTAIN HEADING',
        sub: 'Accord standing drops sharply. Crew respect increases. You\'re now on a list.',
        color: Color(0xFFFF8844),
        loyaltyDelta: 10,
        hopeDelta: 8,
        resolveDelta: 5,
        authorityDelta: -8,
        reputationDelta: -28,
        outcome:
            'You did not respond to the dispatch. '
            'Maintained heading. Maintained silence. '
            'Cpl. Maren reported a course correction error in the nav log — '
            'technically accurate, diplomatically brilliant. '
            'You didn\'t ask her to do that. '
            'The Accord will follow up. That is a certainty.',
      ),
    ],
  ),

  EncounterData(
    id: 'hull_breach',
    title: 'BREACH — PORT COMPARTMENT',
    sectorTag: 'SECTOR 1  —  EMERGENCY ALERT',
    minSector: 1, maxSector: 3,
    story:
        'A microimpact tears a breach in the port cargo section — the civilian quarters block. '
        'Hull integrity dropping. Pvt. Drex is already suited up and moving.\n\n'
        'Sgt. Varro intercepts you in the corridor: "Commander. Drex is good, '
        'but he\'s not rated for emergency EVA. Let me put Cpl. Maren on it." '
        'Drex overhears. He stops. Turns. Doesn\'t say a word.',
    choices: [
      EncounterChoice(
        label: 'LET DREX HANDLE IT — HE\'S ALREADY MOVING',
        sub: 'Drex proves himself. Citizen resentment. Hull partially repaired.',
        color: Color(0xFF00FF88),
        hullDelta: 8,
        civilianLoyaltyDelta: 14,
        citizenLoyaltyDelta: -5,
        empathyDelta: 3,
        outcome:
            'Drex handled the breach in forty-seven minutes. '
            'He came back in trailing exhaust residue and sat down without debriefing. '
            'Sgt. Varro found something to fix on the other side of the ship. '
            'The breach is sealed. '
            'Something else just opened.',
      ),
      EncounterChoice(
        label: 'ORDER CPL. MAREN IN — BY PROTOCOL',
        sub: 'Hull repaired faster. Civilian resentment increases. Drex will not forget this.',
        color: Color(0xFFFF8844),
        hullDelta: 12,
        citizenLoyaltyDelta: 6,
        civilianLoyaltyDelta: -12,
        authorityDelta: 3,
        civilianTensionDelta: 14,
        outcome:
            'Maren sealed the breach in thirty-one minutes. Clean work. '
            'Drex watched from the corridor and then went to his bunk. '
            'Dr. Yessa filed a formal crew welfare concern that evening. '
            'Hull integrity restored. '
            'Your civilian crew just got a number to put on their resentment.',
      ),
      EncounterChoice(
        label: 'SEND BOTH — TOGETHER',
        sub: 'Slower but builds cross-status cooperation. Minor injury risk.',
        color: Color(0xFF00AAFF),
        hullDelta: 10,
        medicineDelta: -3,
        loyaltyDelta: 3,
        empathyDelta: 2,
        orderDelta: 5,
        outcome:
            'They worked together without being told how. '
            'Drex held the patch while Maren welded. '
            'Drex burned his hand on the seal — minor, treated. '
            'They didn\'t talk on the way back in. '
            'But they nodded at each other, and for this crew, that\'s something.',
      ),
    ],
  ),

  EncounterData(
    id: 'vyrathi_signal',
    title: 'RESONANCE — UNKNOWN ORIGIN',
    sectorTag: 'SECTOR 1  —  DEEP COMMS SCAN',
    minSector: 1, maxSector: 3,
    story:
        'A fragmented signal on a frequency outside standard AccordNet bands catches Zhen\'s attention. '
        'After two hours of analysis, she delivers her verdict quietly:\n\n'
        '"Commander, this is Vyrathi. I\'m certain of it. It\'s structured — not noise. '
        'And it\'s directed at us. Specifically. They know our ship\'s configuration." '
        'She hesitates. '
        '"The Accord maintains Vyrathi contact has never been successfully initiated. '
        'But this isn\'t us initiating it. They reached out first."',
    choices: [
      EncounterChoice(
        label: 'ANALYZE AND RESPOND',
        sub: 'Unauthorized alien contact. High knowledge gain. Accord will not approve.',
        color: Color(0xFF00FF88),
        fuelDelta: -5,
        reputationDelta: -12,
        bugSympathyDelta: 8,
        alienKnowledgeDelta: {AlienSpecies.vyrathi: 28},
        outcome:
            'Zhen formulated a response — structured harmonics, mathematically neutral. '
            'You transmitted. '
            'The Vyrathi reply came back in forty seconds: layered, dense, '
            'and according to Zhen, unmistakably an acknowledgement of shared intelligence. '
            'You don\'t know what they wanted. '
            'You know that they know you heard them.',
      ),
      EncounterChoice(
        label: 'RECORD AND MAINTAIN SILENCE',
        sub: 'Cautious. Good data. Safe option.',
        color: Color(0xFF00AAFF),
        salvageDelta: 3,
        creditsDelta: 10,
        bugSympathyDelta: 5,
        alienKnowledgeDelta: {AlienSpecies.vyrathi: 12},
        outcome:
            'You logged the full signal, let Zhen archive it, and held silence. '
            'The Vyrathi did not repeat the transmission. '
            'Whether they concluded you couldn\'t hear them, or that you chose not to answer — '
            'you may never know which they assumed.',
      ),
      EncounterChoice(
        label: 'FULL RADIO SILENCE — CHANGE COURSE',
        sub: 'No contact. No risk. Fuel cost from course correction.',
        color: Color(0xFFFF8844),
        fuelDelta: -10,
        resolveDelta: -2,
        alienKnowledgeDelta: {AlienSpecies.vyrathi: 5},
        outcome:
            'You ordered immediate course change and full signal blackout. '
            'Zhen complied and said nothing. '
            'Later, reviewing her personal log without her knowledge, '
            'you found one line she hadn\'t encrypted: '
            '"We had a chance."',
      ),
    ],
  ),

  EncounterData(
    id: 'the_spy',
    title: 'PRIVATE CONSULTATION',
    sectorTag: 'SECTOR 1  —  COMMANDER\'S QUARTERS',
    minSector: 1, maxSector: 2,
    story:
        'Zhen requests a private meeting in your quarters. They close the door and don\'t sit down.\n\n'
        '"I\'ve been reporting to Civic Intelligence since before we departed. '
        'Everything so far has been classified routine. I\'m telling you because..." '
        'They stop. Start again. '
        '"The next time you defy an Accord order — and I\'ve read the mission parameters, you will — '
        'I won\'t be able to protect the report. '
        'You should know what I am before you decide what I am to you."',
    choices: [
      EncounterChoice(
        label: 'REASSIGN TO NON-SENSITIVE DUTIES — AND THANK THEM',
        sub: 'Trust extended. Civilian crew morale improves. Accord standing drops slightly.',
        color: Color(0xFF00FF88),
        civilianLoyaltyDelta: 10,
        resolveDelta: 3,
        empathyDelta: 3,
        reputationDelta: -5,
        bugSympathyDelta: 5,
        outcome:
            'You thanked them. Reassigned them to xenodata analysis only — '
            'no command access, no comms logs. '
            'Zhen nodded once and accepted it. '
            'What they chose to report after that was their decision, not yours. '
            'The crew never learned why Zhen\'s duties changed. '
            'They noticed anyway.',
      ),
      EncounterChoice(
        label: 'CONFINE THEM PENDING ARRIVAL',
        sub: 'Decisive. Order maintained. Civilian trust collapses.',
        color: Color(0xFFFF8844),
        orderDelta: 5,
        civilianLoyaltyDelta: -18,
        citizenLoyaltyDelta: 5,
        authorityDelta: 3,
        civilianTensionDelta: 22,
        outcome:
            'You confined Zhen to quarters under guard. '
            'Sgt. Varro executed the order without expression. '
            'Dr. Yessa heard through the ventilation and did not come to briefing the next morning. '
            'Pvt. Drex stopped speaking entirely for four days. '
            'Order is maintained. '
            'Something else has broken.',
      ),
      EncounterChoice(
        label: 'MAKE THEM YOUR INTELLIGENCE ASSET',
        sub: 'They report what you want reported. High risk if Accord discovers the arrangement.',
        color: Color(0xFF00AAFF),
        bugSympathyDelta: 12,
        empathyDelta: 3,
        resolveDelta: 3,
        authorityDelta: -3,
        outcome:
            'You told Zhen what you needed the Accord to believe. '
            'They listened. They agreed. '
            'What that says about both of you, you\'ll think about later. '
            'For now, Zhen files reports that are technically accurate and operationally misleading. '
            'The Accord has no reason to doubt their asset. '
            'You have no reason to doubt yours.',
      ),
    ],
  ),

  EncounterData(
    id: 'wreckage_dawnhaven',
    title: 'RSK DAWNHAVEN — DEBRIS FIELD',
    sectorTag: 'SECTOR 1  —  NAVIGATION ALERT',
    minSector: 1, maxSector: 2,
    story:
        'Your sensors locate the wreckage of the civilian freighter RSK Dawnhaven. '
        'No survivors. Hull scoring consistent with Chithari plasma discharge.\n\n'
        'But Zhen flags something in the debris scan and calls you over, voice careful:\n\n'
        '"Commander — the attack pattern. The Chithari didn\'t swarm this ship. '
        'They targeted it. Life support junction nodes, in sequence. '
        'This takes... it requires understanding what a life support junction is." '
        'She doesn\'t finish the thought. She doesn\'t have to.',
    choices: [
      EncounterChoice(
        label: 'LOG AS STANDARD CHITHARI ATTACK — CONTINUE',
        sub: 'Accord-approved narrative. No questions asked. Something goes unexamined.',
        color: Color(0xFFFF8844),
        reputationDelta: 5,
        alienKnowledgeDelta: {AlienSpecies.chithari: 5},
        outcome:
            'You filed it as a standard Chithari engagement. '
            'The Accord will use this in the next propaganda cycle — '
            'another reason why citizens must serve, why the war must continue. '
            'Zhen archived her own analysis separately, in a partition you chose not to inspect.',
      ),
      EncounterChoice(
        label: 'FLAG AS ANOMALOUS — PERSONAL LOG ONLY',
        sub: 'You record the truth privately. Carry the weight of it.',
        color: Color(0xFF00AAFF),
        resolveDelta: -3,
        bugSympathyDelta: 20,
        alienKnowledgeDelta: {AlienSpecies.chithari: 25},
        outcome:
            'You entered a detailed anomaly report in your encrypted personal log. '
            'The attack geometry, the targeting sequence, the implication. '
            'Zhen found out — you let her. '
            'She added her own analysis to your archive. '
            'Between the two of you, you now know something the Accord doesn\'t know you know.',
      ),
      EncounterChoice(
        label: 'REPORT THE ANOMALY TO ACCORDNET',
        sub: 'You report officially. The Accord acknowledges and buries it.',
        color: Color(0xFF00FF88),
        reputationDelta: 5,
        bugSympathyDelta: 8,
        alienKnowledgeDelta: {AlienSpecies.chithari: 12},
        outcome:
            'You submitted a full anomaly report through official channels. '
            'The Accord acknowledged receipt within the hour. '
            'Three days later: a follow-up noting the anomaly had been reviewed and '
            '"attributed to standard swarming behavior with navigational coincidence." '
            'Zhen read the response over your shoulder and walked away without speaking.',
      ),
    ],
  ),

  // ── SECTOR 2+ (teasers for next sprint) ────────────────────────────────────

  EncounterData(
    id: 'kethari_patrol',
    title: "KETH'ARI PATROL INTERCEPT",
    sectorTag: 'SECTOR 2  —  CONTESTED SPACE',
    minSector: 2, maxSector: 4,
    story:
        "Three Keth'ari warships drop out of transit directly ahead. "
        "They don't attack. They hold position and broadcast on open frequency — "
        "a challenge tone, according to Zhen. Not a threat. An invitation.\n\n"
        "\"They respect strength,\" Zhen says. \"Responding with weapons drawn means war. "
        "Responding unarmed means they own you. There's a third option — "
        "but it involves Commander Varro, a lot of eye contact, and absolute stillness.\"",
    choices: [
      EncounterChoice(
        label: 'WEAPONS HOT — HOLD POSITION',
        sub: "Show military readiness. Keth'ari may interpret this as dominance — and close the corridor.",
        color: Color(0xFFFF8844),
        fearDelta: 8,
        citizenLoyaltyDelta: 5,
        alienKnowledgeDelta: {AlienSpecies.kethAri: 10},
        blocksConnection: 'graveyard-kethreach',
        outcome:
            "The Keth'ari held for seven minutes, then peeled off in formation. "
            "Varro exhaled. Zhen noted the departure vector — they were reporting your position. "
            "Within hours, Keth'ari warships sealed the Graveyard corridor. "
            "That route is no longer an option.",
      ),
      EncounterChoice(
        label: 'SEND VARRO FORWARD — UNARMED CHANNEL',
        sub: 'Cultural protocol. High trust if it works. Crew fear spike either way.',
        color: Color(0xFF00FF88),
        fearDelta: 12,
        loyaltyDelta: 5,
        authorityDelta: 3,
        creditsDelta: 20,
        alienKnowledgeDelta: {AlienSpecies.kethAri: 25},
        outcome:
            "Varro stood at the camera feed, arms visible, chin up. "
            "The Keth'ari held their formation for three minutes, then the lead ship "
            "broadcast a single-tone acknowledgement. "
            "Zhen translated it later: roughly, 'we see you.' "
            "In Keth'ari, that's a compliment.",
      ),
      EncounterChoice(
        label: 'TRANSMIT SOLUNE DIPLOMATIC CODES',
        sub: 'Using third-party neutrality. Requires Solune knowledge.',
        color: Color(0xFF00AAFF),
        alienKnowledgeDelta: {AlienSpecies.kethAri: 15, AlienSpecies.solune: 8},
        bugSympathyDelta: 3,
        outcome:
            "The Keth'ari paused, apparently confused. "
            "Then, after a long silence, they withdrew. "
            "Using Solune codes in Keth'ari space is technically an insult "
            "— implying they need a mediator. "
            "Zhen says it probably worked because it was so unexpected they weren't sure how to respond.",
      ),
    ],
  ),

];
