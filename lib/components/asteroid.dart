import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

class Asteroid extends SpriteComponent with HasGameReference<MyGame> {
  final Random _random = Random();
  static const double _maxSize = 120;
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
    _spinSpeed = _random.nextDouble() * 1.5 - 0.75;

    // Determine asteroid type (1, 2, or 3)
    _asteroidType = _random.nextInt(3) + 1;

    // Set base health based on type: Asteroid 1 has 3 health, others have 2
    double baseHealth = (_asteroidType == 1) ? 3.0 : 2.0;

    // Scale health by size (usually size is max so it equals baseHealth)
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

    return Vector2(
          _random.nextDouble() * 120 - 60,
          100 + _random.nextDouble() * 50,
        ) *
        forceFactor;
  }

  void _handleScreenBounds() {
    // remove the asteroid from the game if it goes below the bottom
    if (position.y > game.size.y + size.y / 2) {
      removeFromParent();
    }

    // perform wraparound if the asteroid goes over the left or right edge
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
      // _splitAsteroid(); // Disabled splitting
    } else {
      game.incrementScore(1);
      _flashWhite();
      _applyKnockback();
    }
  }

  void selfDestruct() {
    removeFromParent();
    _createExplosion();
  }

  void _flashWhite() {
    final ColorEffect flashEffect = ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0),
      EffectController(
        duration: 0.1,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );
    add(flashEffect);
  }

  void _applyKnockback() {
    if (_isKnockedback) return;

    _isKnockedback = true;

    _velocity.setZero();

    final MoveByEffect knockbackEffect = MoveByEffect(
      Vector2(0, -20),
      EffectController(
        duration: 0.1,
      ),
      onComplete: _restoreVelocity,
    );
    add(knockbackEffect);
  }

  void _restoreVelocity() {
    _velocity.setFrom(_originalVelocity);

    _isKnockedback = false;
  }

  void _createExplosion() {
    final Explosion explosion = Explosion(
      position: position.clone(),
      explosionSize: size.x,
      explosionType: ExplosionType.dust,
    );
    game.add(explosion);
  }
}
