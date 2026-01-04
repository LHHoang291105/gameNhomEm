import 'dart:async';

import 'package:Phoenix_Blast/components/player.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Coin extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  final int value;
  final double _speed = 250; // Tăng tốc độ rơi
  final bool isVictoryCoin;

  Coin({
    required this.value,
    required super.position,
    this.isVictoryCoin = false,
  }) : super(
          size: Vector2.all(30),
          anchor: Anchor.center,
        );

  @override
  FutureOr<void> onLoad() async {
    final sprites = await Future.wait([
      game.loadSprite('coin.png'),
      game.loadSprite('coin1.png'),
      game.loadSprite('coin2.png'),
      game.loadSprite('coin3.png'),
    ]);

    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: 0.15,
    );
    
    add(CircleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _speed * dt;

    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Player) {
      game.addSessionCoins(value);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

}
