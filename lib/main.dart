import 'dart:async';

import 'package:flutter/material.dart';

import 'pet_controller.dart';

void main() => runApp(const DigitalPetApp());

class DigitalPetApp extends StatelessWidget {
  const DigitalPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Pet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const PetScreen(),
    );
  }
}

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  late final PetController _pet;
  final TextEditingController _nameController = TextEditingController();

  // Short-lived animation state only (not game state).
  bool _bouncing = false;
  Timer? _bounceTimer;

  @override
  void initState() {
    super.initState();
    _pet = PetController(); // starts the single hunger timer
    _nameController.text = _pet.name;
  }

  @override
  void dispose() {
    _bounceTimer?.cancel();
    _pet.dispose(); // cancels hunger + win timers
    _nameController.dispose();
    super.dispose();
  }

  Color get _moodColor => switch (_pet.mood) {
        Mood.happy => Colors.green,
        Mood.neutral => Colors.yellow,
        Mood.unhappy => Colors.red,
      };

  void _act(VoidCallback action) {
    action();
    _bounce();
  }

  /// Replaces any pending bounce reset so an old callback can't end a new one.
  void _bounce() {
    _bounceTimer?.cancel();
    setState(() => _bouncing = true);
    _bounceTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _bouncing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      appBar: AppBar(title: const Text('🐾 Digital Pet')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _pet,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _nameRow(),
                  const SizedBox(height: 12),
                  _petImage(reduceMotion),
                  const SizedBox(height: 8),
                  _moodChip(),
                  const SizedBox(height: 8),
                  _speechBubble(reduceMotion),
                  const SizedBox(height: 16),
                  _Meter(
                    label: 'Happiness',
                    value: _pet.happiness,
                    reduceMotion: reduceMotion,
                  ),
                  _Meter(
                    label: 'Hunger',
                    value: _pet.hunger,
                    reduceMotion: reduceMotion,
                  ),
                  _Meter(
                    label: 'Energy',
                    value: _pet.energy,
                    reduceMotion: reduceMotion,
                  ),
                  const SizedBox(height: 8),
                  _outcomeBanner(),
                  Text(_pet.lastAction, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  _controls(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _nameRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Pet name',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => _pet.setName(v),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => _pet.setName(_nameController.text),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _petImage(bool reduceMotion) {
    final scale = _pet.petScale * (_bouncing ? 1.12 : 1.0);
    return Semantics(
      label: '${_pet.name} the pet, feeling ${_pet.mood.name}',
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: scale,
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(_moodColor, BlendMode.modulate),
            child: Image.asset('assets/pet.png', width: 200, height: 200),
          ),
        ),
      ),
    );
  }

  // Text + emoji so color is never the only mood signal.
  Widget _moodChip() {
    return Chip(
      label: Text('${_pet.name} is ${_pet.moodLabel}'),
    );
  }

  Widget _speechBubble(bool reduceMotion) {
    final message = _pet.petMessage; // derived, never stored
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(message),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('💬 $message'),
      ),
    );
  }

  Widget _outcomeBanner() {
    if (_pet.hasWon) {
      return const _Banner(text: '🏆 You win! Press Reset to play again.');
    }
    if (_pet.gameOver) {
      return const _Banner(text: '💔 Game over. Press Reset to restart.');
    }
    if (_pet.paused) {
      return const _Banner(text: '⏸ Paused. Press Resume to continue.');
    }
    return const SizedBox.shrink();
  }

  Widget _controls() {
    final canAct = _pet.canAct;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: canAct ? () => _act(_pet.play) : null,
          icon: const Icon(Icons.sports_tennis),
          label: const Text('Play'),
        ),
        FilledButton.icon(
          onPressed: canAct ? () => _act(_pet.feed) : null,
          icon: const Icon(Icons.restaurant),
          label: const Text('Feed'),
        ),
        FilledButton.icon(
          onPressed: canAct ? () => _act(_pet.rest) : null,
          icon: const Icon(Icons.bedtime),
          label: const Text('Rest'),
        ),
        OutlinedButton.icon(
          onPressed: (_pet.gameOver || _pet.hasWon)
              ? null
              : (_pet.paused ? _pet.resume : _pet.pause),
          icon: Icon(_pet.paused ? Icons.play_arrow : Icons.pause),
          label: Text(_pet.paused ? 'Resume' : 'Pause'),
        ),
        OutlinedButton.icon(
          onPressed: _pet.reset,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

/// Meter that glides to its value; the number shown always comes from state.
class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.value,
    required this.reduceMotion,
  });

  final String label;
  final int value;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value out of 100',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(label)),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value / 100),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text('$value', textAlign: TextAlign.end),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
