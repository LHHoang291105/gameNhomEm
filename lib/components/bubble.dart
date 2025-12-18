import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class Bubble extends SpriteComponent with HasGameReference<MyGame> {
  final Random _random = Random();

  Bubble() : super(priority: -1); // Let spawner control position

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    sprite = await game.loadSprite('bong2.png');

    final screenWidth = game.size.x;
    final screenHeight = game.size.y;

    // New, even smaller size
    final bubbleSize = 5.0 + _random.nextDouble() * 10.0; 
    size = Vector2.all(bubbleSize);

    // Start just above the screen at a random horizontal position
    position = Vector2(
      _random.nextDouble() * screenWidth,
      -size.y, // Start from the top
    );

    // Bubbles don't need to collide with anything
    // add(CircleHitbox()); 

    // Effect to move the bubble down across the screen and then remove it.
    add(
      MoveByEffect(
        Vector2(0, screenHeight + size.y * 2), // Move down
        EffectController(
          duration: 5.0 + _random.nextDouble() * 5.0, // A bit slower for more natural feel
        ),
        onComplete: removeFromParent,
      ),
    );
  }
}
