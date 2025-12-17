import 'dart:async';

import 'package:cosmic_havoc/components/player.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class MonsterLaser extends SpriteComponent with HasGameRef, CollisionCallbacks {

  MonsterLaser({required super.position}) 
      : super(size: Vector2(20, 40), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('tiaxanh.png');
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 300 * dt;

    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
        removeFromParent();
    }
  }
}
