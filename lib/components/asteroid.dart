import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

class Asteroid extends SpriteComponent with HasGameReference<MyGame> {
  final Random _random = Random();
  
  // YÊU CẦU: Tăng kích thước trở lại
  static const double _maxSize = 100.0; 
  
  late Vector2 _velocity;
  final Vector2 _originalVelocity = Vector2.zero();
  late double _spinSpeed;
  late double _health;
  bool _isKnockedback = false;
  late int _asteroidType;

  Asteroid({required super.position, double size = _maxSize})
      : super(
          size: Vector2.all(size),
          anchor: Anchor.center,
          priority: -1,
        ) {
    _velocity = _generateVelocity();
    _originalVelocity.setFrom(_velocity);
    _spinSpeed = _random.nextDouble() * 1.0 - 0.5; // Giảm tốc độ xoay

    _asteroidType = _random.nextInt(3) + 1;
    double baseHealth = (_asteroidType == 1) ? 3.0 : 2.0;
    _health = size / _maxSize * baseHealth;

    add(CircleHitbox(collisionType: CollisionType.passive));
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
    // YÊU CẦU: Rơi "từ từ" và tự nhiên hơn
    return Vector2(
          _random.nextDouble() * 40 - 20, // Giảm độ lệch ngang để rơi thẳng hơn
          100 + _random.nextDouble() * 100, // Tốc độ rơi ổn định hơn (100-200)
        ) * forceFactor;
  }

  void _handleScreenBounds() {
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }

    final double screenWidth = game.size.x;
    if (position.x < -size.x / 2) {
      position.x = screenWidth + size.x / 2;
    } else if (position.x > screenWidth + size.x / 2) {
      position.x = -size.x / 2;
    }
  }

  void takeDamage() {
    game.audioManager.playSound('hit');
    _health--;

    if (_health <= 0) {
      game.incrementScore(2);
      removeFromParent();
      _createExplosion();
      _maybeDropPickup();
    } else {
      game.incrementScore(1);
      _flashWhite();
      _applyKnockback();
    }
  }

  void _maybeDropPickup() {
    if (_random.nextDouble() < 0.1) { // Giảm tỉ lệ rơi còn 10%
      final type = PickupType.values[_random.nextInt(PickupType.values.length)];
      game.add(Pickup(pickupType: type, position: position.clone()));
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
