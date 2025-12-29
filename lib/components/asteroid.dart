import 'dart:async';
import 'dart:math';

import 'package:Phoenix_Blast/components/coin.dart';
import 'package:Phoenix_Blast/components/explosion.dart';
import 'package:Phoenix_Blast/components/pickup.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

class Asteroid extends SpriteComponent with HasGameReference<MyGame> {
  final Random _random = Random();

  static const double _maxSize = 100.0;

  late Vector2 _velocity;
  final Vector2 _originalVelocity = Vector2.zero();
  late double _spinSpeed;
  late double _health;
  bool _isKnockedback = false;
  late int _asteroidType;

  final bool isFragment;

  Asteroid({required super.position, double size = _maxSize, Vector2? initialVelocity})
      : isFragment = initialVelocity != null,
        super(
          size: Vector2.all(size),
          anchor: Anchor.center,
          priority: -1,
        ) {
    _velocity = initialVelocity ?? _generateVelocity();
    _originalVelocity.setFrom(_velocity);
    _spinSpeed = _random.nextDouble() * 1.0 - 0.5;

    _asteroidType = _random.nextInt(3) + 1;
    
    if (isFragment) {
      _health = 1; 
    } else {
      _health = (_asteroidType == 1) ? 3.0 : 2.0;
    }

    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void onMount() {
    super.onMount();
    if (!isFragment && position.y > 0) {
      position.y = -size.y / 2;
    }
  }

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('asteroid$_asteroidType.png');
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _handleScreenBounds();
    angle += _spinSpeed * dt;
  }

  Vector2 _generateVelocity() {
    final double forceFactor = _maxSize / size.x;
    return Vector2(
          0,
          100 + _random.nextDouble() * 100,
        ) * forceFactor;
  }

  void _handleScreenBounds() {
    if (position.y > game.size.y + 100) {
      removeFromParent();
      return;
    }

    if (position.x < -200 || position.x > game.size.x + 200) {
      removeFromParent();
    }
  }

  void takeDamage({int amount = 1}) {
    game.audioManager.playSound('hit');
    _health -= amount;

    if (_health <= 0) {
      game.incrementScore(2);
      removeFromParent();
      _createExplosion();
      _maybeSpawnSmallerAsteroids();
      _maybeDropPickup();
      _dropCoins(3);
    } else {
      game.incrementScore(1);
      _flashWhite();
      _applyKnockback();
      _dropCoins(1);
    }
  }

  void _maybeSpawnSmallerAsteroids() {
    if (game.currentLevel == 1 &&
        game.distanceTraveled >= 5000 &&
        game.distanceTraveled <= 12000 &&
        size.x > _maxSize / 2) {
      int numberOfSmallerAsteroids = _random.nextInt(4);

      for (int i = 0; i < numberOfSmallerAsteroids; i++) {
        final newSize = size.x / 2;
        if (newSize < 25) continue;

        final newVelocity = Vector2(
          (_random.nextDouble() - 0.5) * 150,
          (_random.nextDouble() * 100) + 75,
        );

        final newAsteroid = Asteroid(
            position: position.clone(),
            size: newSize,
            initialVelocity: newVelocity);
        game.add(newAsteroid);
      }
    }
  }

  void _maybeDropPickup() {
    if (_random.nextDouble() < 0.1) {
      final type = PickupType.values[_random.nextInt(PickupType.values.length)];
      game.add(Pickup(pickupType: type, position: position.clone()));
    }
  }

  void _dropCoins(int count) {
    for (int i = 0; i < count; i++) {
      game.add(Coin(value: 1, position: position.clone()));
    }
  }

  void selfDestruct() {
    removeFromParent();
    _createExplosion();
  }

  void _flashWhite() {
    add(ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0),
      EffectController(duration: 0.1, alternate: true),
    ));
  }

  void _applyKnockback() {
    if (_isKnockedback) return;
    _isKnockedback = true;
    _velocity.setZero();

    add(MoveByEffect(
      Vector2(0, -20),
      EffectController(duration: 0.1),
      onComplete: _restoreVelocity,
    ));
  }

  void _restoreVelocity() {
    _velocity.setFrom(_originalVelocity);
    _isKnockedback = false;
  }

  void _createExplosion() {
    game.add(Explosion(
      position: position.clone(),
      explosionSize: size.x,
      explosionType: ExplosionType.dust,
    ));
  }
}
