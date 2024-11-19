import 'package:flutter/material.dart';
import 'sprite_animation.dart';

class KladisIdle extends StatelessWidget {
  const KladisIdle({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/Idle.png',
      frameCount: 2,
      row: 0,
      frameWidth: 16,
      frameHeight: 16,
      duration: Duration(seconds: 1),
      isLooping: true,
    );
  }
}

class KloudIdle extends StatelessWidget {
  const KloudIdle({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/Idle.png',
      frameCount: 2,
      row: 1,
      frameWidth: 16,
      frameHeight: 16,
      duration: Duration(seconds: 1),
      isLooping: true,
    );
  }
}

class KladisCorrect extends StatelessWidget {
  const KladisCorrect({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/AdvSpriteSheet.png',
      frameCount: 2,
      row: 0,
      frameWidth: 16,
      frameHeight: 16,
      duration: Duration(seconds: 1),
      isLooping: false,
    );
  }
}

class KloudCorrect extends StatelessWidget {
  const KloudCorrect({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/AdvSpriteSheet.png',
      frameCount: 2,
      row: 1,
      frameWidth: 16,
      frameHeight: 16,
      duration: Duration(seconds: 1),
      isLooping: false,
    );
  }
}

class KladisWrong extends StatelessWidget {
  const KladisWrong({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/AdvSpriteSheet.png',
      frameCount: 7,
      row: 2,
      frameWidth: 16,
      frameHeight: 16,
      duration: Duration(seconds: 1),
      isLooping: false,
      startFrame: 0,
    );
  }
}

class KloudWrong extends StatelessWidget {
  const KloudWrong({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/AdvSpriteSheet.png',
      frameCount: 7,
      row: 2,
      frameWidth: 16,
      frameHeight: 16,
      duration: Duration(seconds: 1),
      isLooping: false,
      startFrame: 7,
    );
  }
}

class KladisDead extends StatelessWidget {
  const KladisDead({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/AdvSpriteSheet.png',
      frameCount: 7,
      row: 0,
      frameWidth: 32,
      frameHeight: 16,
      duration: Duration(seconds: 1, milliseconds: 500),
      isLooping: false,
      startFrame: 2,
      scale: 1.0,
    );
  }
}

class KloudDead extends StatelessWidget {
  const KloudDead({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpriteAnimation(
      spritePath: 'assets/sprite-sheets/AdvSpriteSheet.png',
      frameCount: 7,
      row: 1,
      frameWidth: 32,
      frameHeight: 16,
      duration: Duration(seconds: 1, milliseconds: 500),
      isLooping: false,
      startFrame: 2,
      scale: 1.0,
    );
  }
}