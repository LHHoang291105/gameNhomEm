import 'dart:async' hide Timer;
import 'dart:math';
import 'dart:ui';

import 'package:Phoenix_Blast/components/asteroid.dart';
import 'package:Phoenix_Blast/components/boss_monster.dart';
import 'package:Phoenix_Blast/components/coin.dart';
import 'package:Phoenix_Blast/components/explosion.dart';
import 'package:Phoenix_Blast/components/laser.dart';
import 'package:Phoenix_Blast/components/monster.dart';
import 'package:Phoenix_Blast/components/monster_laser.dart';
import 'package:Phoenix_Blast/components/red_laser.dart';
import 'package:Phoenix_Blast/components/pickup.dart';
import 'package:Phoenix_Blast/components/shield.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<MyGame>, KeyboardHandler, CollisionCallbacks {
  bool _isShooting = false;
  final double _fireCooldown = 0.2;
  double _elapsedFireTime = 0.0;
  final Vector2 _keyboardMovement = Vector2.zero();
  bool _isDestroyed = false;
  bool isTransitioning = false;
  final Random _random = Random();
  late Timer _explosionTimer;
  late Timer _laserPowerupTimer;
  late Timer _shieldPowerupTimer;
  Shield? activeShield;
  late String _skin;
  final String currentSkill;

  late Sprite _destructionSprite;

  int lives = 3;
  bool _isInvincible = false;
  late Timer _invincibilityTimer;

  Player({
    required String skin,
    int? lives,
    required this.currentSkill,
  }) : _skin = skin {
    if (lives != null) {
      this.lives = lives;
    }
    _explosionTimer = Timer(0.15, onTick: _createRandomExplosion, repeat: true, autoStart: false);
    _laserPowerupTimer = Timer(4.0, onTick: () {}, autoStart: false);
    _shieldPowerupTimer = Timer(4.0, onTick: _deactivateShield, autoStart: false);
    _invincibilityTimer = Timer(1.5, onTick: () => _isInvincible = false, autoStart: false);
  }

  bool get isLaserActive => _laserPowerupTimer.isRunning();
  double get laserRemainingTime => _laserPowerupTimer.limit - _laserPowerupTimer.current;
  bool get hasShield => activeShield != null;
  bool get isDestroyed => _isDestroyed;

  @override
  FutureOr<void> onLoad() async {
    List<Sprite> animationSprites = [];
    if (_skin == 'vang') {
      animationSprites = await Future.wait([
        game.loadSprite('vang1.png'),
        game.loadSprite('vang2.png'),
        game.loadSprite('vang3.png'),
      ]);
    } else if (_skin == 'maybay') {
      animationSprites = await Future.wait([
        game.loadSprite('maybay1.png'),
        game.loadSprite('maybay2.png'),
      ]);
    } else if (_skin == 'player_red_off') {
      animationSprites = await Future.wait([
        game.loadSprite('player_red_on0.png'),
        game.loadSprite('player_red_on1.png'),
      ]);
    } else if (_skin == 'player_blue_off') {
      animationSprites = await Future.wait([
        game.loadSprite('player_blue_on0.png'),
        game.loadSprite('player_blue_on1.png'),
      ]);
    } else if (_skin == 'chienco_hong') {
      animationSprites = await Future.wait([
        game.loadSprite('chienco_hong1.png'),
        game.loadSprite('chienco_hong2.png'),
      ]);
    } else if (_skin == 'chienco_xanh') {
      animationSprites = await Future.wait([
        game.loadSprite('chienco_xanh1.png'),
        game.loadSprite('chienco_xanh2.png'),
      ]);
    }

    animation = SpriteAnimation.spriteList(
      animationSprites,
      stepTime: 0.1,
      loop: true,
    );

    _destructionSprite = await game.loadSprite('$_skin.png');

    size = Vector2(1024, 1024) * 0.05;
    anchor = Anchor.center;

    add(RectangleHitbox.relative(
      Vector2(0.6, 0.9),
      parentSize: size,
      anchor: Anchor.center,
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDestroyed) {
      _explosionTimer.update(dt);
      return;
    }
    _laserPowerupTimer.update(dt);
    _shieldPowerupTimer.update(dt);
    _invincibilityTimer.update(dt);

    if (!isTransitioning) {
      final Vector2 movement = game.joystick.relativeDelta + _keyboardMovement;
      position += movement.normalized() * 200 * dt;
      _handleScreenBounds();
    }

    _elapsedFireTime += dt;
    if (_isShooting && _elapsedFireTime >= _fireCooldown) {
      _fireLaser();
      _elapsedFireTime = 0.0;
    }
  }

  void _handleScreenBounds() {
    position.y = clampDouble(position.y, size.y / 2, game.size.y - size.y / 2);
    position.x = clampDouble(position.x, size.x / 2, game.size.x - size.x / 2);
  }

  void startShooting() => _isShooting = true;
  void stopShooting() => _isShooting = false;

  void _fireLaser() {
    game.audioManager.playSound('laser');
    final skill = currentSkill;
    final spawnPos = position.clone() + Vector2(0, -size.y / 2);

    switch (skill) {
      case 'skill_samxet':
        game.add(Laser(position: spawnPos, spriteName: 'skill_samxet.png', damage: 2));
        if (isLaserActive) {
          game.add(Laser(position: spawnPos, spriteName: 'skill_samxet.png', damage: 2, angle: 15 * degrees2Radians));
          game.add(Laser(position: spawnPos, spriteName: 'skill_samxet.png', damage: 2, angle: -15 * degrees2Radians));
        }
        break;
      case 'skill_hinhtron':
        game.add(HinhtronProjectile(position: spawnPos));
        if (isLaserActive) {
          game.add(HinhtronProjectile(position: spawnPos, angle: 15 * degrees2Radians));
          game.add(HinhtronProjectile(position: spawnPos, angle: -15 * degrees2Radians));
        }
        break;
      case 'skill_cauvong':
        for (var i = -1; i <= 1; i++) {
          game.add(Laser(
            position: spawnPos,
            angle: i * 15 * degrees2Radians,
            spriteName: 'skill_cauvong.png',
            damage: 1,
          ));
        }
        if (isLaserActive) {
          game.add(Laser(position: spawnPos, angle: 30 * degrees2Radians, spriteName: 'skill_cauvong.png', damage: 1));
          game.add(Laser(position: spawnPos, angle: -30 * degrees2Radians, spriteName: 'skill_cauvong.png', damage: 1));
        }
        break;
      default:
        game.add(Laser(position: spawnPos, spriteName: 'laser.png', damage: 1));
        if (isLaserActive) {
          game.add(Laser(position: spawnPos, spriteName: 'laser.png', damage: 1, angle: 15 * degrees2Radians));
          game.add(Laser(position: spawnPos, spriteName: 'laser.png', damage: 1, angle: -15 * degrees2Radians));
        }
        break;
    }
  }

  void _activateInvincibility() {
    _isInvincible = true;
    _invincibilityTimer.start();
    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.1, reverseDuration: 0.1, repeatCount: 7),
    ));
  }

  void _handleDestruction() {
    if (_isDestroyed) return;
    _isDestroyed = true;
    animation = SpriteAnimation.spriteList([_destructionSprite], stepTime: double.infinity);
    game.add(Explosion(position: position.clone(), explosionSize: size.x * 2, explosionType: ExplosionType.fire));
    add(OpacityEffect.fadeOut(EffectController(duration: 2.0), onComplete: () => _explosionTimer.stop()));
    add(MoveEffect.by(Vector2(0, 150), EffectController(duration: 2.0)));
    add(RemoveEffect(delay: 2.5, onComplete: game.playerDied));
    _explosionTimer.start();
  }

  void _createRandomExplosion() {
    final explosionPosition = Vector2(position.x - size.x / 2 + _random.nextDouble() * size.x, position.y - size.y / 2 + _random.nextDouble() * size.y);
    final explosionType = _random.nextBool() ? ExplosionType.smoke : ExplosionType.fire;
    game.add(Explosion(position: explosionPosition, explosionSize: size.x * 0.7, explosionType: explosionType));
  }

  void _deactivateShield() {
    if (activeShield != null) {
      activeShield!.removeFromParent();
      activeShield = null;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_isDestroyed || isTransitioning) {
      if (kDebugMode) {
        print('Collision ignored: _isDestroyed=$_isDestroyed, isTransitioning=$isTransitioning');
      }
      return;
    }

    if (other is Asteroid || other is Monster || other is MonsterLaser || other is RedLaser || other is BossMonster) {
      if (kDebugMode) {
        print('Collision with ${other.runtimeType}');
      }
      if (_isInvincible || hasShield) return;

      lives--;
      game.updatePlayerHealth(lives);
      if (lives <= 0) {
        _handleDestruction();
      } else {
        _activateInvincibility();
      }
    } else if (other is Pickup) {
      game.audioManager.playSound('collect');
      other.removeFromParent();
      game.incrementScore(1);
      switch (other.pickupType) {
        case PickupType.laser:
          _laserPowerupTimer.start();
          break;
        case PickupType.bomb:
          game.add(BombExplosion(position: position.clone()));
          break;
        case PickupType.heart:
          lives++;
          game.updatePlayerHealth(lives);
          break;
        case PickupType.shield:
          if (!hasShield) {
            activeShield = Shield();
            add(activeShield!);
          }
          _shieldPowerupTimer.start();
          break;
      }
    } else if (other is Coin) {
      game.audioManager.playSound('collect');
      game.addSessionCoins(other.value);
      other.removeFromParent();
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardMovement.x = 0;
    _keyboardMovement.x += keysPressed.contains(LogicalKeyboardKey.arrowLeft) ? -1 : 0;
    _keyboardMovement.x += keysPressed.contains(LogicalKeyboardKey.arrowRight) ? 1 : 0;
    _keyboardMovement.y = 0;
    _keyboardMovement.y += keysPressed.contains(LogicalKeyboardKey.arrowUp) ? -1 : 0;
    _keyboardMovement.y += keysPressed.contains(LogicalKeyboardKey.arrowDown) ? 1 : 0;
    return true;
  }
}

class HinhtronProjectile extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  final double _speed = 600;
  final int damage = 3;

  HinhtronProjectile({required super.position, super.angle})
      : super(
          size: Vector2.all(30),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('skill_hinhtron.png');
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += sin(angle - pi / 2) * _speed * dt;
    position.x += cos(angle - pi / 2) * _speed * dt;

    if (position.y < -size.y || position.x < -size.x || position.x > game.size.x + size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player || other is Pickup || other is Coin) {
      return;
    }

    game.add(Explosion(position: other.center, explosionSize: 60, explosionType: ExplosionType.fire));
    removeFromParent();
    game.audioManager.playSound('explosion');

    if (other is Asteroid) {
      other.takeDamage(amount: damage);
    } else if (other is Monster) {
      other.takeDamage(amount: damage);
    } else if (other is BossMonster) {
      other.takeDamage(amount: damage);
    } else if (other is MonsterLaser || other is RedLaser) {
      other.removeFromParent();
    }
  }
}

class BombExplosion extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  BombExplosion({required super.position})
      : super(
          anchor: Anchor.center,
          size: Vector2.all(10.0),
        );

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('bomb.png');
    add(CircleHitbox(collisionType: CollisionType.active));

    game.audioManager.playSound('explosion');

    add(
      SizeEffect.to(
        Vector2.all(300),
        EffectController(
          duration: 0.6,
          curve: Curves.easeOutCirc,
        ),
      ),
    );

    // Glow effect by flashing a color, then fade out.
    add(
      SequenceEffect([
        ColorEffect(
          Colors.yellow.withOpacity(0.8),
          EffectController(
            duration: 0.15,
            alternate: true,
            repeatCount: 2,
          ),
        ),
        OpacityEffect.fadeOut(
          EffectController(
            duration: 0.3,
            curve: Curves.easeIn,
          ),
        ),
        RemoveEffect(),
      ]),
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player || other is Pickup || other is Coin) {
      return;
    }

    if (other is Asteroid) {
      other.selfDestruct();
    } else if (other is Monster) {
      other.takeDamage(fromBomb: true);
    } else if (other is BossMonster) {
      other.takeDamage(amount: 10);
    } else if (other is MonsterLaser || other is RedLaser) {
      other.removeFromParent();
    }
  }
}
