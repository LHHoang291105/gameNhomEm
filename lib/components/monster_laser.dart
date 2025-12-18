import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class MonsterLaser extends SpriteComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final double _speed = 250; // Reduced speed

  MonsterLaser({
    required super.position,
    required super.angle,
  }) : super(
          size: Vector2(20, 40), // Adjust size as needed
          anchor: Anchor.center,
        );

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('tiaxanh.png');
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move in the direction of the angle
    position.x += _speed * dt * cos(angle - pi / 2);
    position.y += _speed * dt * sin(angle - pi / 2);

    // Remove if it goes off screen
    if (position.y > game.size.y ||
        position.y < -size.y ||
        position.x > game.size.x ||
        position.x < -size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // The logic to handle collision with the player is in the player component
    // So we just need to remove the laser itself.
    removeFromParent();
  }
}
