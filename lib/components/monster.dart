import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/monster_laser.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Monster extends SpriteComponent with HasGameReference<MyGame> {
  final Random _random = Random();
  late Timer _fireTimer;
  late Vector2 _velocity;

  Monster({required super.position}) 
      : super(size: Vector2.all(80), anchor: Anchor.center, priority: -1) {
    // Add a slight horizontal drift to the downward velocity
    _velocity = Vector2((_random.nextDouble() - 0.5) * 80, 80 + _random.nextDouble() * 100);
  }

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    String spritePath;

    if (game.currentLevel == 2) {
      final monsterType = _random.nextInt(3) + 1;
      spritePath = 'monster_saothuy$monsterType.png';
      _fireTimer = Timer(3.0 + _random.nextDouble() * 3, onTick: _fireLaser, repeat: true);
    } else if (game.currentLevel == 3) {
      final useVariant = _random.nextBool();
      spritePath = useVariant ? 'monster_mini_sao_HOA.png' : 'monster_mini_sao_hoa_2.png';
      _fireTimer = Timer(2.0 + _random.nextDouble() * 2, onTick: _fireLaser, repeat: true);
    } else {
      spritePath = 'monster_saothuy1.png'; // Fallback
      _fireTimer = Timer(3.0 + _random.nextDouble() * 3, onTick: _fireLaser, repeat: true);
    }

    try {
      sprite = await game.loadSprite(spritePath);
    } catch(e) {
      try {
         sprite = await game.loadSprite('monster_saothuy1.png');
      } catch(e2) {
         // Last resort
      }
    }

    add(CircleHitbox(collisionType: CollisionType.passive));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _fireTimer.update(dt);
    
    position += _velocity * dt;

    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  void _fireLaser() {
    if (isMounted && game.children.whereType<Player>().isNotEmpty) {
      final playerPosition = game.player.position;
      final monsterPosition = position;
      // Correct angle calculation to point at the player
      final angle = atan2(playerPosition.y - monsterPosition.y, playerPosition.x - monsterPosition.x) - pi / 2;

      final laser = MonsterLaser(
        position: position.clone(),
        angle: angle,
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
      game.incrementScore(5);
  }
}
