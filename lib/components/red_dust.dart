import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RedDust extends CircleComponent with HasGameRef {
  final Random _random = Random();
  late double _speed;

  RedDust() : super(anchor: Anchor.center) {
    paint.color = Colors.red.withOpacity(0.5 + _random.nextDouble() * 0.3);
  }

  @override
  Future<void> onLoad() {
    size = Vector2.all(1.0 + _random.nextDouble() * 2);
    _speed = 30 + _random.nextDouble() * 40;

    // Spawn at the top
    position = Vector2(
      _random.nextDouble() * game.size.x,
      -size.y,
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _speed * dt; // Move downwards

    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
}
