import 'package:digital_pet/pet_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clamping / action rules', () {
    test('feed at hunger 5 stays in 0-100 and uses resulting hunger', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(hunger: 5, happiness: 50);
      p.feed();
      expect(p.hunger, 0); // 5 - 10 clamped
      expect(p.happiness, 30); // resulting hunger < 30 -> -20
      p.dispose();
    });

    test('feed at hunger 95 lowers hunger and raises happiness', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(hunger: 95, happiness: 50);
      p.feed();
      expect(p.hunger, 85);
      expect(p.happiness, 60);
      p.dispose();
    });

    test('play at happiness 95 clamps to 100', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(happiness: 95, energy: 80);
      p.play();
      expect(p.happiness, 100);
      p.dispose();
    });

    test('play at energy 5 is refused and explained', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(energy: 5, happiness: 50, hunger: 30);
      p.play();
      expect(p.energy, 5);
      expect(p.happiness, 50);
      expect(p.hunger, 30);
      expect(p.lastAction, contains('Too tired'));
      p.dispose();
    });

    test('rest clamps energy at 100', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(energy: 95);
      p.rest();
      expect(p.energy, 100);
      p.dispose();
    });
  });

  group('mood thresholds', () {
    final cases = {
      29: Mood.unhappy,
      30: Mood.neutral,
      70: Mood.neutral,
      71: Mood.happy,
    };
    cases.forEach((value, expected) {
      test('happiness $value -> ${expected.name}', () {
        final p = PetController(hungerInterval: const Duration(hours: 1));
        p.debugSet(happiness: value);
        expect(p.mood, expected);
        p.dispose();
      });
    });

    test('scale follows the same bands', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(happiness: 29);
      expect(p.petScale, 0.94);
      p.debugSet(happiness: 50);
      expect(p.petScale, 1.0);
      p.debugSet(happiness: 71);
      expect(p.petScale, 1.06);
      p.dispose();
    });
  });

  group('hunger timer', () {
    test('adds 5 every interval', () {
      fakeAsync((async) {
        final p = PetController();
        p.debugSet(hunger: 30);
        async.elapse(const Duration(seconds: 30));
        expect(p.hunger, 35);
        async.elapse(const Duration(seconds: 30));
        expect(p.hunger, 40);
        p.dispose();
      });
    });

    test('95 -> 100 has no penalty; next tick clamps and costs 20', () {
      fakeAsync((async) {
        final p = PetController();
        p.debugSet(hunger: 95, happiness: 50);
        async.elapse(const Duration(seconds: 30));
        expect(p.hunger, 100);
        expect(p.happiness, 50);
        async.elapse(const Duration(seconds: 30));
        expect(p.hunger, 100);
        expect(p.happiness, 30);
        p.dispose();
      });
    });
  });

  group('win rule', () {
    test('wins after 3 continuous minutes above 80', () {
      fakeAsync((async) {
        final p = PetController(hungerInterval: const Duration(hours: 1));
        p.debugSet(happiness: 85);
        expect(p.winTimerActive, isTrue);
        async.elapse(const Duration(minutes: 2, seconds: 59));
        expect(p.hasWon, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(p.hasWon, isTrue);
        p.dispose();
      });
    });

    test('exactly 80 does not qualify', () {
      fakeAsync((async) {
        final p = PetController(hungerInterval: const Duration(hours: 1));
        p.debugSet(happiness: 80);
        expect(p.winTimerActive, isFalse);
        async.elapse(const Duration(minutes: 5));
        expect(p.hasWon, isFalse);
        p.dispose();
      });
    });

    test('dropping to 80 at 2:59 cancels; a fresh crossing restarts 3:00', () {
      fakeAsync((async) {
        final p = PetController(hungerInterval: const Duration(hours: 1));
        p.debugSet(happiness: 85);
        async.elapse(const Duration(minutes: 2, seconds: 59));
        p.debugSet(happiness: 80);
        expect(p.winTimerActive, isFalse);
        async.elapse(const Duration(minutes: 1));
        expect(p.hasWon, isFalse);

        p.debugSet(happiness: 85);
        expect(p.winTimerActive, isTrue);
        async.elapse(const Duration(minutes: 2, seconds: 59));
        expect(p.hasWon, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(p.hasWon, isTrue);
        p.dispose();
      });
    });

    test('win stops the hunger timer and disables actions', () {
      fakeAsync((async) {
        final p = PetController(hungerInterval: const Duration(seconds: 30));
        p.debugSet(happiness: 85, hunger: 0);
        async.elapse(const Duration(minutes: 3));
        expect(p.hasWon, isTrue);
        final hungerAtWin = p.hunger;
        async.elapse(const Duration(minutes: 2));
        expect(p.hunger, hungerAtWin);
        p.feed();
        expect(p.hunger, hungerAtWin);
        expect(p.canAct, isFalse);
        p.dispose();
      });
    });
  });

  group('loss rule', () {
    test('hunger 100 and happiness 10 -> game over, actions disabled', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(hunger: 100, happiness: 10);
      expect(p.gameOver, isTrue);
      final before = p.happiness;
      p.play();
      p.feed();
      p.rest();
      expect(p.happiness, before);
      expect(p.canAct, isFalse);
      p.dispose();
    });

    test('hunger 100 but happiness 11 is not game over', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(hunger: 100, happiness: 11);
      expect(p.gameOver, isFalse);
      p.dispose();
    });
  });

  group('pause / reset', () {
    test('pause stops hunger and the win timer; resume restarts', () {
      fakeAsync((async) {
        final p = PetController();
        p.debugSet(happiness: 85, hunger: 30);
        p.pause();
        expect(p.winTimerActive, isFalse);
        async.elapse(const Duration(minutes: 5));
        expect(p.hunger, 30);
        expect(p.hasWon, isFalse);
        p.resume();
        expect(p.winTimerActive, isTrue);
        async.elapse(const Duration(seconds: 30));
        expect(p.hunger, 35);
        p.dispose();
      });
    });

    test('reset restores state, clears win timer, leaves ONE hunger timer', () {
      fakeAsync((async) {
        final p = PetController();
        p.debugSet(happiness: 85);
        p.reset();
        expect(p.happiness, PetController.initialHappiness);
        expect(p.hunger, PetController.initialHunger);
        expect(p.energy, PetController.initialEnergy);
        expect(p.winTimerActive, isFalse);
        expect(p.gameOver, isFalse);
        expect(p.hasWon, isFalse);
        async.elapse(const Duration(seconds: 30));
        // two timers would give +10
        expect(p.hunger, PetController.initialHunger + 5);
        p.dispose();
      });
    });

    test('reset after game over re-enables actions', () {
      final p = PetController(hungerInterval: const Duration(hours: 1));
      p.debugSet(hunger: 100, happiness: 10);
      p.reset();
      expect(p.canAct, isTrue);
      p.dispose();
    });
  });

  group('lifecycle', () {
    test('dispose cancels timers; no activity afterwards', () {
      fakeAsync((async) {
        final p = PetController();
        p.debugSet(happiness: 85);
        p.dispose();
        async.elapse(const Duration(minutes: 10));
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
