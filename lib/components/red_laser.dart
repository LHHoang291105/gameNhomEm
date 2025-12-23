import 'dart:async';
import 'dart:math';
import 'package:Phoenix_Blast/components/player.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class RedLaser extends SpriteComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed; 

  RedLaser({
    required super.position, 
    required this.direction,
    required this.speed,
  }) : super(
    size: Vector2(40, 120), // Tăng kích thước to và dài hơn hẳn
    anchor: Anchor.center,
    priority: 15,
  );

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('red_laser.png');
    angle = atan2(direction.y, direction.x) - pi / 2;
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;

    if (position.y > game.size.y + 200 || position.y < -200 || 
        position.x > game.size.x + 200 || position.x < -200) {
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
