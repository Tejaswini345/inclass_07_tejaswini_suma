import 'dart:async';

import 'package:flutter/foundation.dart';

enum Mood { happy, neutral, unhappy }

/// Owns ALL pet/game rules and both timers. The widget tree only renders it.
///
/// Ownership boundary (README design note):
///  - PetController: meters, outcomes, hunger timer, win timer, pause/reset.
///  - PetScreen (UI): text field, animations, reduced motion, layout.
///
/// Trade-off: timers live in a ChangeNotifier instead of the State object.
/// That makes rules testable with fake_async (no widgets needed), but the
/// screen must remember to call dispose() on the controller.
class PetController extends ChangeNotifier {
  PetController({
    this.hungerInterval = const Duration(seconds: 30), // restore to 30 s!
    this.winDuration = const Duration(minutes: 3), // restore to 3 min!
    String name = 'Pip',
  }) : _name = name {
    _startHungerTimer();
  }

  final Duration hungerInterval;
  final Duration winDuration;

  // Initial balance (documented rules, see README).
  static const int initialHappiness = 50;
  static const int initialHunger = 30;
  static const int initialEnergy = 80;

  // Action rules.
  static const int feedHungerDrop = 10;
  static const int playHappinessGain = 15;
  static const int playHungerGain = 5;
  static const int playEnergyCost = 15;
  static const int playMinEnergy = 10; // below this, play is refused
  static const int restEnergyGain = 25;
  static const int restHungerGain = 5;

  String _name;
  int _happiness = initialHappiness;
  int _hunger = initialHunger;
  int _energy = initialEnergy;
  bool _gameOver = false;
  bool _hasWon = false;
  bool _paused = false;
  bool _disposed = false;
  String _lastAction = 'Say hi to your pet!';

  Timer? _hungerTimer;
  Timer? _winTimer;

  // ---- read-only state -----------------------------------------------------
  String get name => _name;
  int get happiness => _happiness;
  int get hunger => _hunger;
  int get energy => _energy;
  bool get gameOver => _gameOver;
  bool get hasWon => _hasWon;
  bool get paused => _paused;
  String get lastAction => _lastAction;
  bool get canAct => !_gameOver && !_hasWon && !_paused;

  @visibleForTesting
  bool get winTimerActive => _winTimer != null;

  // ---- derived presentation (never stored) --------------------------------
  Mood get mood {
    if (_happiness > 70) return Mood.happy;
    if (_happiness >= 30) return Mood.neutral;
    return Mood.unhappy;
  }

  String get moodLabel => switch (mood) {
        Mood.happy => 'Happy 😄',
        Mood.neutral => 'Okay 😐',
        Mood.unhappy => 'Unhappy 😢',
      };

  double get petScale => switch (mood) {
        Mood.happy => 1.06,
        Mood.neutral => 1.0,
        Mood.unhappy => 0.94,
      };

  String get petMessage {
    if (_gameOver) return 'I need a rest.';
    if (_hasWon) return 'Best day ever!';
    if (_paused) return 'Paused... zzz';
    if (_hunger > 80) return "I'm starving!";
    if (_happiness <= 30) return 'Play with me?';
    if (_energy < 20) return 'So sleepy...';
    return "Hi, I'm $_name!";
  }

  // ---- helpers ------------------------------------------------------------
  static int clampMeter(int value) => value.clamp(0, 100).toInt();

  // ---- actions ------------------------------------------------------------
  void setName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _name = trimmed;
    _lastAction = 'Name set to $_name.';
    _notify();
  }

  void feed() {
    if (!canAct) return;
    final nextHunger = clampMeter(_hunger - feedHungerDrop);
    // Suggested rule: feeding a pet that is not hungry upsets it.
    final change = nextHunger < 30 ? -20 : 10;
    _hunger = nextHunger;
    _happiness = clampMeter(_happiness + change);
    _lastAction = change > 0
        ? 'Feed: Hunger -$feedHungerDrop, Happiness +10.'
        : 'Feed: Not hungry! Happiness -20.';
    _afterChange();
  }

  void play() {
    if (!canAct) return;
    if (_energy < playMinEnergy) {
      _lastAction = 'Play: Too tired! Let $_name rest first.';
      _notify();
      return;
    }
    _happiness = clampMeter(_happiness + playHappinessGain);
    _hunger = clampMeter(_hunger + playHungerGain);
    _energy = clampMeter(_energy - playEnergyCost);
    _lastAction = 'Play: Happiness +$playHappinessGain, '
        'Hunger +$playHungerGain, Energy -$playEnergyCost.';
    _afterChange();
  }

  void rest() {
    if (!canAct) return;
    _energy = clampMeter(_energy + restEnergyGain);
    _hunger = clampMeter(_hunger + restHungerGain);
    _lastAction = 'Rest: Energy +$restEnergyGain, Hunger +$restHungerGain.';
    _afterChange();
  }

  void pause() {
    if (!canAct) return;
    _paused = true;
    _cancelTimers(); // win progress is intentionally lost (continuity rule)
    _lastAction = 'Paused.';
    _notify();
  }

  void resume() {
    if (!_paused || _gameOver || _hasWon) return;
    _paused = false;
    _startHungerTimer();
    _lastAction = 'Resumed.';
    _evaluate(); // restarts a fresh win timer if happiness is still > 80
    _notify();
  }

  void reset() {
    _cancelTimers();
    _happiness = initialHappiness;
    _hunger = initialHunger;
    _energy = initialEnergy;
    _gameOver = false;
    _hasWon = false;
    _paused = false;
    _lastAction = 'Reset: fresh start!';
    _startHungerTimer(); // cancels any old one first -> exactly one active
    _notify();
  }

  // ---- timers -------------------------------------------------------------
  void _startHungerTimer() {
    _hungerTimer?.cancel();
    _hungerTimer = Timer.periodic(hungerInterval, (timer) {
      if (_disposed || !canAct) {
        timer.cancel();
        return;
      }
      _onHungerTick();
    });
  }

  void _onHungerTick() {
    if (_hunger + 5 > 100) {
      _hunger = 100;
      _happiness = clampMeter(_happiness - 20);
      _lastAction = 'Time: Starving! Happiness -20.';
    } else {
      _hunger += 5;
      _lastAction = 'Time: Hunger +5.';
    }
    _afterChange();
  }

  void _onWin() {
    _winTimer = null;
    if (_disposed || _gameOver || _paused || _happiness <= 80) return;
    _hasWon = true;
    _cancelTimers();
    _lastAction = 'You win! Happiness stayed above 80.';
    _notify();
  }

  void _cancelTimers() {
    _hungerTimer?.cancel();
    _hungerTimer = null;
    _winTimer?.cancel();
    _winTimer = null;
  }

  // ---- outcome rules ------------------------------------------------------
  void _afterChange() {
    _evaluate();
    _notify();
  }

  void _evaluate() {
    if (_gameOver || _hasWon) return;

    if (_hunger == 100 && _happiness <= 10) {
      _gameOver = true;
      _cancelTimers();
      _lastAction = 'Game over: hunger 100 and happiness $_happiness.';
      return;
    }

    if (_happiness <= 80) {
      // exactly 80 does NOT qualify; cancel and clear immediately
      _winTimer?.cancel();
      _winTimer = null;
      return;
    }

    _winTimer ??= Timer(winDuration, _onWin);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Test/dev helper: jump meters to specific values and re-run the rules.
  @visibleForTesting
  void debugSet({int? happiness, int? hunger, int? energy}) {
    if (happiness != null) _happiness = clampMeter(happiness);
    if (hunger != null) _hunger = clampMeter(hunger);
    if (energy != null) _energy = clampMeter(energy);
    _afterChange();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }
}
