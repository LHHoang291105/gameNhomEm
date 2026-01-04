import 'dart:async' hide Timer;
import 'dart:math';

import 'package:Phoenix_Blast/components/coin.dart';
import 'package:Phoenix_Blast/components/explosion.dart';
import 'package:Phoenix_Blast/components/pickup.dart';
import 'package:Phoenix_Blast/components/red_laser.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class BossMonster extends SpriteAnimationComponent with HasGameReference<MyGame>, CollisionCallbacks {
  late Timer _fireTimer;
  
  int health = 100;
  int _hitCount = 0;
  int _hitsForCoin = 0; // Added for coin drop
  bool _isMovingToCenter = true;
  bool _isTransitioning = false; 
  bool _isMidPhaseTransitioning = false;
  bool _hasTriggeredMidPhase = false;
  bool _canShoot = true;
  
  final Vector2 _originalPosition = Vector2.zero();
  late RectangleComponent _healthBarFill;
  final double _healthBarWidth = 150.0;

  BossMonster({required super.position}) 
      : super(size: Vector2.all(200), anchor: Anchor.center, priority: 1);
  @override
  FutureOr<void> onLoad() async {
    final sprites = [
      await game.loadSprite('monster_saohoa1.png'),
      await game.loadSprite('monster_saohoa2.png'),
      await game.loadSprite('monster_saohoa3.png'),
      await game.loadSprite('monster_saohoa4.png'),
    ];

    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: 0.2,
      loop: true,
    );

    add(CircleHitbox());

    _createHealthBar();
    _originalPosition.setValues(game.size.x / 2, game.size.y * 0.25);

    add(MoveToEffect(
      _originalPosition,
      EffectController(duration: 2.0, curve: Curves.easeOut),
      onComplete: () {
        _isMovingToCenter = false;
        _fireTimer.start();
      },
    ));

    _fireTimer = Timer(0.8, onTick: _decideFireLogic, repeat: true, autoStart: false);
    
    return super.onLoad();
  }

  void _createHealthBar() {
    final healthBarBg = RectangleComponent(
      size: Vector2(_healthBarWidth, 10),
      position: Vector2(size.x / 2, -30),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.grey.withOpacity(0.5),
    );
    add(healthBarBg);

    _healthBarFill = RectangleComponent(
      size: Vector2(_healthBarWidth, 10),
      position: Vector2(0, 0),
      paint: Paint()..color = Colors.green,
    );
    healthBarBg.add(_healthBarFill);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isMovingToCenter && !_isMidPhaseTransitioning) {
        _fireTimer.update(dt);
        position.x = game.size.x / 2 + sin(game.currentTime() * 1.5) * 150;
    }
  }

  void _decideFireLogic() {
    if (!isMounted || _isMidPhaseTransitioning) return;
    
    Vector2 direction;
    double speed;
    if (health > 50) {
      direction = Vector2(0, 1);
      speed = 350;
    } else if (health > 20) {
      direction = (game.player.position - position).normalized();
      speed = 200;
    } else {
      direction = (game.player.position - position).normalized();
      speed = 400;
    }
    
    game.add(RedLaser(position: position.clone()..y += 160, direction: direction, speed: speed));
  }

  void _startMidPhaseTransition() {
    _hasTriggeredMidPhase = true;
    _isMidPhaseTransitioning = true;
    _canShoot = false;
    
    Future.delayed(const Duration(seconds: 5), () {
      if (!isMounted) return;
      _isMidPhaseTransitioning = false;
      _canShoot = true;
    });
  }

  void _startEnragedTransition() {
    _isTransitioning = true;
    _canShoot = false;
    
    add(MoveToEffect(
      Vector2(game.size.x / 2, game.size.y / 2),
      EffectController(duration: 1.5, curve: Curves.easeInOut),
      onComplete: () {
        _triggerAlarmEffect();
        
        Future.delayed(const Duration(seconds: 5), () {
          if (!isMounted) return;
          _fireTimer.limit = 0.6;
          add(MoveToEffect(_originalPosition, EffectController(duration: 1.0)));
        });
      }
    ));
  }

  void _triggerAlarmEffect() {
    final alarm = RectangleComponent(
      size: game.size,
      paint: Paint()..color = Colors.red.withOpacity(0.2),
      priority: 99,
    );
    game.add(alarm);
    alarm.add(OpacityEffect.to(0.0, EffectController(duration: 0.5, reverseDuration: 0.5, repeatCount: 5), onComplete: () => alarm.removeFromParent()));
  }

  void takeDamage({int amount = 1}) {
    if (_isTransitioning || _isMidPhaseTransitioning) return;

    health -= amount;

    // Coin and pickup drop logic
    if (amount == 1) { // Assuming player bullets have amount = 1
      _hitCount++;
      _hitsForCoin++;
    }

    if (_hitsForCoin >= 3) {
      _dropCoins(1); // Drops 1 coin
      _hitsForCoin = 0;
    }
    
    if (_hitCount >= 10) { 
      _hitCount = 0; 
      _dropRandomPickup(); 
    }
    
    _healthBarFill.size.x = (health / 100).clamp(0, 1) * _healthBarWidth;
    
    if (health <= 20) {
      _healthBarFill.paint.color = Colors.red;
    }

    add(ColorEffect(const Color(0xFFFF0000), EffectController(duration: 0.1, reverseDuration: 0.1)));
    
    if (health <= 50 && !_hasTriggeredMidPhase) {
      _startMidPhaseTransition();
    } 

    if (health <= 0) {
      game.bossDefeated();
      removeFromParent();
      _explode();
    }
  }

  void takeBombDamage(int damage) {
    takeDamage(amount: damage);
  }

  void _dropRandomPickup() {
    final types = [PickupType.bomb, PickupType.shield, PickupType.laser];
    final type = types[Random().nextInt(types.length)];
    game.add(Pickup(pickupType: type, position: position.clone()));
  }

  void _dropCoins(int count) {
    for (int i = 0; i < count; i++) {
      // Boss drops coins of value 3.
      game.add(Coin(value: 3, position: position.clone()));
    }
  }

  void _explode() {
    for (int i = 0; i < 8; i++) {
      game.add(Explosion(position: position.clone()..add(Vector2((Random().nextDouble()-0.5)*250, (Random().nextDouble()-0.5)*250)), explosionSize: 200, explosionType: ExplosionType.fire));
    }
    game.incrementScore(5000);
  }
}
