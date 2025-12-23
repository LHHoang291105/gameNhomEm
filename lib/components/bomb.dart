import 'dart:async';
import 'package:Phoenix_Blast/components/asteroid.dart';
import 'package:Phoenix_Blast/components/boss_monster.dart';
import 'package:Phoenix_Blast/components/monster.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Bomb extends SpriteComponent with HasGameReference<MyGame>, CollisionCallbacks {
  Bomb({required super.position})
      : super(size: Vector2.all(80), anchor: Anchor.center, priority: 5);

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('bomb_pickup.png');
    add(CircleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 400 * dt;
    if (position.y < -size.y) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Asteroid || other is Monster || other is BossMonster) {
      if (other is Asteroid) other.selfDestruct();
      if (other is Monster) other.takeDamage();
      if (other is BossMonster) other.takeDamage(amount: 10);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
