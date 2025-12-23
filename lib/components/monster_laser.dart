import 'dart:async';

import 'package:Phoenix_Blast/components/player.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class MonsterLaser extends SpriteComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final Vector2 direction;
  final double _speed = 200; // Tốc độ chậm lại đáng kể (từ 350 xuống 200)

  MonsterLaser({
    required super.position,
    required this.direction,
  }) : super(
          size: Vector2(45, 120), // Tăng kích thước to thêm (từ 30x80 lên 45x120)
          anchor: Anchor.center,
          priority: 10,
        );

  @override
  FutureOr<void> onLoad() async {
    String laserSprite = game.currentLevel == 3 ? 'tiatim.png' : 'tiaxanh.png';
    sprite = await game.loadSprite(laserSprite);
    
    angle = 0;
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * _speed * dt;

    if (position.y > game.size.y + 150 || position.y < -150) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      super.onCollisionStart(intersectionPoints, other);
      removeFromParent();
    }
  }
}
