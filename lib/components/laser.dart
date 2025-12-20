import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/monster.dart';
import 'package:cosmic_havoc/components/boss_monster.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Laser extends SpriteComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final double _speed = 900; // Tăng tốc độ bay để đạn dứt khoát hơn

  Laser({
    required super.position,
    super.angle,
  }) : super(
          size: Vector2(15, 40), 
          anchor: Anchor.center,
          priority: 5,
        );

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('laser.png');
    
    // ĐỘ NHẠY: Đặt hitbox vừa vặn nhưng hơi rộng ra 2 bên một chút (1.5 lần)
    // để dễ trúng mục tiêu mà không bị chồng lấn quá mức giữa 3 tia
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
    // Di chuyển theo góc bắn
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
    // Chỉ xử lý nếu tia laser này chưa bị đánh dấu xóa
    if (isRemoving || isRemoved) return;

    if (other is Asteroid) {
      other.takeDamage();
      removeFromParent(); // Xóa ngay viên đạn trúng đích
    } else if (other is Monster) {
      other.takeDamage();
      removeFromParent();
    } else if (other is BossMonster) {
      other.takeDamage(amount: 1);
      removeFromParent();
    }
    
    super.onCollisionStart(intersectionPoints, other);
  }
}
