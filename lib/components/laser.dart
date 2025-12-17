import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/monster.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Laser extends SpriteComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final double _speed = 800;

  Laser({
    required super.position,
    super.angle,
  }) : super(
          size: Vector2(10, 30),
          anchor: Anchor.center,
          priority: 5, // Tăng priority để hiện lên trên background và quái
        );

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('laser.png');
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Di chuyển theo hướng góc quay
    position.y -= _speed * dt * (cos(angle));
    position.x += _speed * dt * (sin(angle));

    if (position.y < -size.y || position.x < 0 || position.x > game.size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Asteroid) {
      other.takeDamage();
      removeFromParent();
    } else if (other is Monster) {
      other.takeDamage();
      removeFromParent();
    }
  }
}
