import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/audio_manager.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/components/shoot_button.dart';
import 'package:cosmic_havoc/components/star.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late SpawnComponent _asteroidSpawner;
  late SpawnComponent _pickupSpawner;
  final Random _random = Random();
  late ShootButton _shootButton;
  
  // Distance tracking
  double _distanceTraveled = 0.0;
  final double _targetDistance = 1000.0; // 1000km
  // Adjusted speed: 1000km in 60 seconds => 16.67 km/s
  final double _speedKmPerSecond = 1000.0 / 60.0; 
  late TextComponent _distanceDisplay;

  int _score = 0;
  late TextComponent _scoreDisplay;
  final List<String> playerColors = ['red', 'blue'];
  int playerColorIndex = 0;
  late final AudioManager audioManager;
  bool _levelTransitioning = false;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    // initialize the audio manager and play the music
    audioManager = AudioManager();
    await add(audioManager);
    audioManager.playMusic();

    _createStars();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Only increase distance if game is playing (player exists) and not yet transitioning
    if (children.whereType<Player>().isNotEmpty && !_levelTransitioning) {
      _distanceTraveled += _speedKmPerSecond * dt;
      
      // Update display text
      _distanceDisplay.text = '${_distanceTraveled.toInt()} km';
      
      // Check for level transition condition (Distance >= 1000km)
      if (_distanceTraveled >= _targetDistance) {
        _distanceTraveled = _targetDistance; // Cap it at target
        _distanceDisplay.text = '${_targetDistance.toInt()} km';
        _startLevelTransition();
      }
    }
  }

  void startGame() async {
    _levelTransitioning = false;
    _distanceTraveled = 0.0; // Reset distance
    
    await _createJoystick();
    await _createPlayer();
    _createShootButton();
    _createAsteroidSpawner();
    _createPickupSpawner();
    _createScoreDisplay();
    _createDistanceDisplay();
  }

  Future<void> _createPlayer() async {
    player = Player()
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y * 0.8);
    add(player);
  }

  Future<void> _createJoystick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: await loadSprite('joystick_knob.png'),
        size: Vector2.all(50),
      ),
      background: SpriteComponent(
        sprite: await loadSprite('joystick_background.png'),
        size: Vector2.all(100),
      ),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, size.y - 20),
      priority: 10,
    );
    add(joystick);
  }

  void _createShootButton() {
    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 20, size.y - 20)
      ..priority = 10;
    add(_shootButton);
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(position: _generateSpawnPosition()),
      minPeriod: 0.7,
      maxPeriod: 1.2,
      selfPositioning: true,
    );
    add(_asteroidSpawner);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(
        position: _generateSpawnPosition(),
        pickupType:
            PickupType.values[_random.nextInt(PickupType.values.length)],
      ),
      minPeriod: 5.0,
      maxPeriod: 10.0,
      selfPositioning: true,
    );
    add(_pickupSpawner);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(
      10 + _random.nextDouble() * (size.x - 10 * 2),
      -100,
    );
  }

  void _createScoreDisplay() {
    _score = 0;

    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20), // Top Center
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );

    add(_scoreDisplay);
  }
  
  void _createDistanceDisplay() {
    _distanceDisplay = TextComponent(
      text: '0 km',
      anchor: Anchor.topLeft,
      position: Vector2(20, 20), // Top Left
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    add(_distanceDisplay);
  }

  void incrementScore(int amount) {
    // Score is kept for tracking kills/pickups but no longer triggers level transition
    if (_levelTransitioning) return;

    _score += amount;
    _scoreDisplay.text = _score.toString();

    final ScaleEffect popEffect = ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(
        duration: 0.05,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );

    _scoreDisplay.add(popEffect);
  }

  void _startLevelTransition() {
    if (_levelTransitioning) return;
    _levelTransitioning = true;

    // Stop spawners
    _asteroidSpawner.timer.stop();
    _pickupSpawner.timer.stop();

    // Destroy all existing asteroids
    children.whereType<Asteroid>().forEach((asteroid) {
      asteroid.selfDestruct();
    });
    
    // Logic for completing level (reaching 1000km)
  }

  void _createStars() {
    for (int i = 0; i < 50; i++) {
      add(Star()..priority = -10);
    }
  }

  void playerDied() {
    overlays.add('GameOver');
    pauseEngine();
  }

  void restartGame() {
    _levelTransitioning = false;
    _distanceTraveled = 0.0;

    // remove any asteroids and pickups that are currently in the game
    children.whereType<PositionComponent>().forEach((component) {
      if (component is Asteroid || component is Pickup) {
        remove(component);
      }
    });

    // reset the asteroid and pickup spawners
    _asteroidSpawner.timer.start();
    _pickupSpawner.timer.start();

    // reset the score to 0
    _score = 0;
    _scoreDisplay.text = '0';
    _distanceDisplay.text = '0 km';

    // create a new player sprite
    _createPlayer();

    resumeEngine();
  }

  void quitGame() {
    _levelTransitioning = false;
    _distanceTraveled = 0.0;
    
    // remove everything from the game except the stars
    children.whereType<PositionComponent>().forEach((component) {
      if (component is! Star) {
        remove(component);
      }
    });

    remove(_asteroidSpawner);
    remove(_pickupSpawner);
    
    // Also remove score and distance displays
    if (contains(_scoreDisplay)) remove(_scoreDisplay);
    if (contains(_distanceDisplay)) remove(_distanceDisplay);

    // show the title overlay
    overlays.add('Title');

    resumeEngine();
  }
}
