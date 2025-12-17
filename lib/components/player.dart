import 'dart:async' hide Timer;
import 'dart:math';
import 'dart:ui';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/bomb.dart';
import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/components/monster.dart';
import 'package:cosmic_havoc/components/monster_laser.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/shield.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/services.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<MyGame>, KeyboardHandler, CollisionCallbacks {
  bool _isShooting = false;
  final double _fireCooldown = 0.2;
  double _elapsedFireTime = 0.0;
  final Vector2 _keyboardMovement = Vector2.zero();
  bool _isDestroyed = false;
  final Random _random = Random();
  late Timer _explosionTimer;
  late Timer _laserPowerupTimer;
  Shield? activeShield;
  late String _color;

  late Sprite _destructionSprite; // Store the destruction sprite

  // Health and Invincibility
  int lives = 3;
  bool _isInvincible = false;
  late Timer _invincibilityTimer;

  Player() {
    _explosionTimer = Timer(0.1, onTick: _createRandomExplosion, repeat: true, autoStart: false);
    _laserPowerupTimer = Timer(10.0, autoStart: false);
    _invincibilityTimer = Timer(1.5, onTick: () => _isInvincible = false, autoStart: false);
  }
  
  bool get isLaserActive => _laserPowerupTimer.isRunning();
  double get laserRemainingTime => _laserPowerupTimer.limit - _laserPowerupTimer.current;
  bool get hasShield => activeShield != null;

  @override
  FutureOr<void> onLoad() async {
    _color = game.playerColors[game.playerColorIndex];

    // FIX: Load images directly using loadSprite instead of fromCache
    final sprite1 = await game.loadSprite('player_${_color}_on0.png');
    final sprite2 = await game.loadSprite('player_${_color}_on1.png');
    
    // Pre-load destruction sprite
    _destructionSprite = await game.loadSprite('player_${_color}_off.png');

    animation = SpriteAnimation.spriteList(
      [sprite1, sprite2],
      stepTime: 0.1,
      loop: true,
    );

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
    _invincibilityTimer.update(dt);

    final Vector2 movement = game.joystick.relativeDelta + _keyboardMovement;
    position += movement.normalized() * 200 * dt;

    _handleScreenBounds();

    _elapsedFireTime += dt;
    if (_isShooting && _elapsedFireTime >= _fireCooldown) {
      _fireLaser();
      _elapsedFireTime = 0.0;
    }
  }

  void _handleScreenBounds() {
    final double screenWidth = game.size.x;
    final double screenHeight = game.size.y;

    position.y = clampDouble(position.y, size.y / 2, screenHeight - size.y / 2);
    position.x = clampDouble(position.x, size.x / 2, screenWidth - size.x / 2);
  }

  void startShooting() => _isShooting = true;
  void stopShooting() => _isShooting = false;

  void _fireLaser() {
    game.audioManager.playSound('laser');
    game.add(Laser(position: position.clone() + Vector2(0, -size.y / 2)));

    if (_laserPowerupTimer.isRunning()) {
      game.add(Laser(position: position.clone() + Vector2(0, -size.y / 2), angle: 15 * degrees2Radians));
      game.add(Laser(position: position.clone() + Vector2(0, -size.y / 2), angle: -15 * degrees2Radians));
    }
  }

  void _activateInvincibility() {
    _isInvincible = true;
    _invincibilityTimer.start();
    
    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.1, alternate: true, repeatCount: 15),
    ));
  }

  void _handleDestruction() {
    if (_isDestroyed) return;
    _isDestroyed = true;

    // Use the pre-loaded sprite
    animation = SpriteAnimation.spriteList(
      [_destructionSprite],
      stepTime: double.infinity,
    );

    add(OpacityEffect.fadeOut(EffectController(duration: 3.0), onComplete: () => _explosionTimer.stop()));
    add(MoveEffect.by(Vector2(0, 200), EffectController(duration: 3.0)));
    add(RemoveEffect(delay: 4.0, onComplete: game.playerDied));

    _explosionTimer.start();
  }

  void _createRandomExplosion() {
    final explosionPosition = Vector2(
      position.x - size.x / 2 + _random.nextDouble() * size.x,
      position.y - size.y / 2 + _random.nextDouble() * size.y,
    );

    final explosionType = _random.nextBool() ? ExplosionType.smoke : ExplosionType.fire;
    game.add(Explosion(position: explosionPosition, explosionSize: size.x * 0.7, explosionType: explosionType));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (_isDestroyed || _isInvincible) return;

    bool hit = false;
    if (other is Asteroid || other is Monster || other is MonsterLaser) {
        hit = true;
    }

    if(hit) {
        if (activeShield != null) {
            activeShield!.removeFromParent();
            activeShield = null;
            _activateInvincibility();
        } else {
            lives--;
            game.updatePlayerHealth(lives);
            if (lives <= 0) {
               _handleDestruction();
            } else {
               _activateInvincibility();
            }
        }
    }
    else if (other is Pickup) {
      game.audioManager.playSound('collect');
      other.removeFromParent();
      game.incrementScore(1);

      switch (other.pickupType) {
        case PickupType.laser:
          _laserPowerupTimer.start();
          break;
        case PickupType.bomb:
          game.add(Bomb(position: position.clone()));
          break;
        case PickupType.shield:
          if (activeShield != null) {
            activeShield!.removeFromParent();
          }
          activeShield = Shield();
          add(activeShield!);
          break;
      }
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
