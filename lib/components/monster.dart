import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/monster_laser.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

class Monster extends SpriteComponent with HasGameReference<MyGame> {
  final Random _random = Random();
  late Timer _fireTimer;

  Monster({required super.position}) : super(size: Vector2.all(80), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    String spritePath;

    if (game.currentLevel == 2) {
      // FIX: Use the specific images for Level 2
      final monsterType = _random.nextInt(3) + 1; // 1, 2, or 3
      spritePath = 'monster_saothuy$monsterType.png';
    } else if (game.currentLevel == 3) {
      final useVariant = _random.nextBool();
      spritePath = useVariant ? 'monster_mini_sao_HOA.png' : 'monster_mini_sao_hoa_2.png';
    } else {
      spritePath = 'monster_saothuy1.png'; // Fallback
    }

    try {
      sprite = await game.loadSprite(spritePath);
    } catch(e) {
      // Fallback if asset is missing to prevent crash
      // Assuming at least one exists, or use asteroid as placeholder
      try {
         sprite = await game.loadSprite('monster_saothuy1.png');
      } catch(e2) {
         // Last resort
      }
    }

    _fireTimer = Timer(2.0 + _random.nextDouble() * 2, onTick: _fireLaser, repeat: true);
    add(CircleHitbox());

    // Effect: Move down into screen if spawned above, then hover
    if (position.y < 0) {
       add(MoveToEffect(
         Vector2(position.x, _random.nextDouble() * game.size.y * 0.4 + 50), 
         EffectController(duration: 2.0, curve: Curves.easeOut),
         onComplete: () {
            _startHovering();
         }
       ));
    } else {
       _startHovering();
    }

    return super.onLoad();
  }
  
  void _startHovering() {
    add(MoveToEffect(
      _getRandomVector(),
      EffectController(duration: 3.0, curve: Curves.easeInOut, alternate: true, repeatCount: -1),
    ));
  }

  Vector2 _getRandomVector() {
    return Vector2(
      _random.nextDouble() * game.size.x,
      _random.nextDouble() * game.size.y * 0.4 + 50, 
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _fireTimer.update(dt);
    
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  void _fireLaser() {
    if (isMounted) {
      final laser = MonsterLaser(position: position.clone() + Vector2(0, size.y / 2));
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
  }
}
