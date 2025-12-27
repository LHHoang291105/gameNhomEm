import 'dart:async';
import 'dart:math';

import 'package:Phoenix_Blast/components/asteroid.dart';
import 'package:Phoenix_Blast/components/monster.dart';
import 'package:Phoenix_Blast/components/boss_monster.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Laser extends SpriteComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final double _speed = 900;
  final int damage;
  final String spriteName;

  Laser({
    required super.position,
    super.angle,
    this.damage = 1,
    this.spriteName = 'laser.png',
  }) : super(
          size: Vector2(15, 40),
          anchor: Anchor.center,
          priority: 5,
        );

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite(spriteName);

    add(RectangleHitbox.relative(
      Vector2(1.5, 1.0),
      parentSize: size,
      anchor: Anchor.center,
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _speed * dt * sin(angle ?? 0);
    position.y -= _speed * dt * cos(angle ?? 0);

    if (position.y < -size.y || position.x < -size.x || position.x > game.size.x + size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (isRemoving || isRemoved) return;

    if (other is Asteroid) {
      other.takeDamage();
      removeFromParent();
    } else if (other is Monster) {
      other.takeDamage();
      removeFromParent();
    } else if (other is BossMonster) {
      other.takeDamage(amount: damage);
      removeFromParent();
    }

    super.onCollisionStart(intersectionPoints, other);
  }
}
