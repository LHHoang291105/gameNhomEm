import 'dart:async';

import 'package:Phoenix_Blast/components/asteroid.dart';
import 'package:Phoenix_Blast/components/boss_monster.dart';
import 'package:Phoenix_Blast/components/monster.dart';
import 'package:Phoenix_Blast/components/monster_laser.dart';
import 'package:Phoenix_Blast/components/red_laser.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

class Shield extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  Shield() : super(size: Vector2.all(200), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('shield.png');

    position += game.player.size / 2;

    add(CircleHitbox());

    final ScaleEffect pulsatingEffect = ScaleEffect.to(
      Vector2.all(1.1),
      EffectController(
        duration: 0.6,
        alternate: true,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    );
    add(pulsatingEffect);

    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Asteroid || other is Monster || other is MonsterLaser || other is RedLaser || other is BossMonster) {
      if (other is Asteroid) {
        other.takeDamage();
      } else if (other is Monster) {
        other.takeDamage();
      } else if (other is MonsterLaser) {
        other.removeFromParent();
      } else if (other is RedLaser) {
        other.removeFromParent();
      } else if (other is BossMonster) {
        // Shield doesn't destroy the boss, but could do minor damage or nothing
      }
    }
  }
}
