import 'dart:async';
import 'dart:math';

import 'package:Phoenix_Blast/components/coin.dart';
import 'package:Phoenix_Blast/components/explosion.dart';
import 'package:Phoenix_Blast/components/monster_laser.dart';
import 'package:Phoenix_Blast/components/pickup.dart';
import 'package:Phoenix_Blast/components/player.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Monster extends SpriteAnimationComponent with HasGameReference<MyGame> {
  final Random _random = Random();
  late Timer _fireTimer;
  late Vector2 _velocity;
  
  final double _baseFallSpeed = 70.0;
  
  double _time = 0;
  double _amplitude = 0;
  double _frequency = 0;

  Monster({required super.position}) 
      : super(size: Vector2.all(80), anchor: Anchor.center, priority: -1);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    position.y = -250 - _random.nextDouble() * 200;
    
    // Tăng tốc độ rơi theo level
    double minFallSpeed = 40.0;
    double maxFallSpeedAdd = 50.0;
    if (game.currentLevel == 2) {
      minFallSpeed = 70.0;
      maxFallSpeedAdd = 100.0;
    } else if (game.currentLevel == 3) {
      minFallSpeed = 70.0;
      maxFallSpeedAdd = 110.0;
    }
    
    final randomFallSpeed = minFallSpeed + _random.nextDouble() * maxFallSpeedAdd;
    _velocity = Vector2(0, randomFallSpeed);

    if (game.currentLevel >= 2) {
      _amplitude = 40 + _random.nextDouble() * 60;
      _frequency = 1 + _random.nextDouble() * 1.4;
      _time = _random.nextDouble() * pi * 2;
    }

    List<Sprite> animationSprites = [];
    double stepTime = 0.15;

    if (game.currentLevel == 2) {
      if (_random.nextBool()) {
        animationSprites = [
          await game.loadSprite('monster_saothuy1.png'),
          await game.loadSprite('monster_saothuy1.1.png'),
        ];
      } else {
        animationSprites = [
          await game.loadSprite('monster_saothuy3.png'),
          await game.loadSprite('monster_saothuy3.1.png'),
          await game.loadSprite('monster_saothuy3.2.png'),
        ];
      }
      _fireTimer = Timer(2.0, onTick: _fireLaser, repeat: true);
    } else if (game.currentLevel == 3) {
      // Random chọn 1 trong 2 loại quái màn 3
      if (_random.nextBool()) {
        animationSprites = [
          await game.loadSprite('monster_mini_sao_hoa_2.png'),
          await game.loadSprite('monster_mini_sao_hoa_2.1.png'),
        ];
      } else {
        animationSprites = [
          await game.loadSprite('monster_mini_sao_hoa_1.png'),
          await game.loadSprite('monster_mini_sao_hoa_1.1.png'),
          await game.loadSprite('monster_mini_sao_hoa_1.2.png'),
        ];
      }
      _fireTimer = Timer(1.5, onTick: _fireLaser, repeat: true);
    } else {
      animationSprites = [await game.loadSprite('monster_saothuy1.png')];
      _fireTimer = Timer(3.0, onTick: _fireLaser, repeat: true);
    }

    animation = SpriteAnimation.spriteList(
      animationSprites,
      stepTime: stepTime,
      loop: true,
    );

    add(CircleHitbox(collisionType: CollisionType.passive));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _fireTimer.update(dt);
    _time += dt;

    position.y += _velocity.y * dt;

    if (_amplitude > 0) {
      position.x += sin(_time * _frequency) * _amplitude * dt;
    }

    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  void _fireLaser() {
    if (isMounted && position.y > -100 && position.y < game.size.y - 100) {
      final laser = MonsterLaser(
        position: position.clone()..y += 50,
        direction: Vector2(0, 1),
      );
      game.add(laser);
    }
  }
  
  void takeDamage() {
      removeFromParent();
      game.add(Explosion(
        position: position.clone(), 
        explosionSize: size.x,
        explosionType: ExplosionType.fire,
      ));
      game.incrementScore(10);
      _maybeDropPickup();
      _dropCoins(3);
  }

  void _maybeDropPickup() {
    if (_random.nextDouble() < 0.2) {
      final type = PickupType.values[_random.nextInt(PickupType.values.length)];
      game.add(Pickup(pickupType: type, position: position.clone()));
    }
  }

  void _dropCoins(int count) {
    for (int i = 0; i < count; i++) {
      game.add(Coin(value: 1, position: position.clone()));
    }
  }

  void explodeSilently() {
    removeFromParent();
    game.add(Explosion(
      position: position.clone(), 
      explosionSize: size.x,
      explosionType: ExplosionType.fire,
    ));
  }
}
