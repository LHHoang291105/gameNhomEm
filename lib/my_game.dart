import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/audio_manager.dart';
import 'package:cosmic_havoc/components/bubble.dart';
import 'package:cosmic_havoc/components/monster.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/components/red_dust.dart';
import 'package:cosmic_havoc/components/shoot_button.dart';
import 'package:cosmic_havoc/components/star.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  final Random _random = Random();
  ShootButton? _shootButton;
  final List<String> playerColors = ['red', 'blue'];
  int playerColorIndex = 0;

  // Sprites
  late Sprite _joystickKnobSprite;
  late Sprite _joystickBackgroundSprite;
  late Sprite _shieldIconSprite;
  late Sprite _laserIconSprite;
  
  SpawnComponent? _asteroidSpawner;
  SpawnComponent? _monsterSpawner;
  SpawnComponent? _pickupSpawner;
  SpawnComponent? _bubbleSpawner;
  SpawnComponent? _redDustSpawner;

  int currentLevel = 1;
  bool _levelTransitioning = false;
  SpriteComponent? _background;

  // Level settings
  double _distanceTraveled = 0.0;
  final List<double> _levelTargets = [12000.0, 30000.0];
  final int _maxLevel = 3;
  final double _speedKmPerSecond = 12000.0 / 30.0; 

  TextComponent? _distanceDisplay;
  RectangleComponent? _progressBar;
  RectangleComponent? _progressFill;
  TextComponent? _healthDisplay;
  SpriteComponent? _shieldIcon;
  SpriteComponent? _laserIcon;
  TextComponent? _scoreDisplay;
  HamburgerMenuComponent? _menuBtn; 
  int _score = 0;

  late final AudioManager audioManager;
  late final double _safeTop;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    // Pre-load all UI assets
    _joystickKnobSprite = await loadSprite('joystick_knob.png');
    _joystickBackgroundSprite = await loadSprite('joystick_background.png');
    _shieldIconSprite = await loadSprite('shield_pickup.png');
    _laserIconSprite = await loadSprite('laser_pickup.png');

    _safeTop = WidgetsBinding.instance.window.padding.top / WidgetsBinding.instance.window.devicePixelRatio;

    audioManager = AudioManager();
    await add(audioManager);
    audioManager.playMusic();
    
    _createStars();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (children.whereType<Player>().isNotEmpty && player.isMounted) {
      _updatePowerupsDisplay();

      if (!_levelTransitioning) {
        _distanceTraveled += _speedKmPerSecond * dt;

        double currentTarget = (_levelTargets.length >= currentLevel) ? _levelTargets[currentLevel - 1] : double.infinity;
        double progressBase = (currentLevel > 1) ? _levelTargets[currentLevel - 2] : 0;
        double levelDistance = currentTarget - progressBase;

        if (_distanceDisplay != null && _progressFill != null) {
            double progress = (levelDistance > 0) ? (_distanceTraveled - progressBase) / levelDistance : 0.0;
            
            if (progress > 1.0) progress = 1.0;
            if (progress < 0.0) progress = 0.0;

            _progressFill!.size = Vector2(10, 200 * progress);
            _distanceDisplay!.text = '${_distanceTraveled.toInt()} km';
        }

        if (currentLevel < _maxLevel && _distanceTraveled >= currentTarget) {
          _distanceTraveled = currentTarget;
          if (_distanceDisplay != null) {
             _distanceDisplay!.text = '${currentTarget.toInt()} km';
          }
          _startLevelTransition();
        }
      }
    }
  }

  void _updatePowerupsDisplay() {
    if (_shieldIcon == null || _laserIcon == null) return;
    if (!player.isMounted) return;

    _shieldIcon!.opacity = player.hasShield ? 1 : 0;

    if (!player.isLaserActive) {
      _laserIcon!.opacity = 0;
      return;
    }

    if (player.laserRemainingTime < 3.0) {
      const blinkSpeed = 10.0;
      _laserIcon!.opacity =
          (sin(player.laserRemainingTime * blinkSpeed) + 1) / 2;
    } else {
      _laserIcon!.opacity = 1.0;
    }
  }

  Future<void> startGame() async {
    currentLevel = 1;
    _distanceTraveled = 0.0;
    _levelTransitioning = false;
    _score = 0;
    
    // Create player first to have access to player.lives
    await _createPlayer();
    // Then create UI that might depend on player state
    _createUI();

    _setupLevel();
  }

  void _setupLevel() {
    // Clean up old level components
    children.whereType<Asteroid>().forEach((a) => a.removeFromParent());
    children.whereType<Monster>().forEach((m) => m.removeFromParent());
    children.whereType<Bubble>().forEach((b) => b.removeFromParent());
    children.whereType<RedDust>().forEach((d) => d.removeFromParent());
    
    _background?.removeFromParent();
    _background = null;
    _removeSpawners();

    // Reset progress bar for the new level
    if (currentLevel > 1 && _progressFill != null && contains(_progressFill!)) {
      _progressFill!.size = Vector2(10, 0);
    }

    // Setup new level components
    if (currentLevel == 1) {
      if (children.whereType<Star>().isEmpty) _createStars();
      _createAsteroidSpawner();
    } else if (currentLevel == 2) {
      children.whereType<Star>().forEach((s) => s.removeFromParent());
      _createSaoThuyBackground();
      _createBubbleSpawner();
      _createMonsterSpawner();
    } else if (currentLevel == 3) {
      children.whereType<Star>().forEach((s) => s.removeFromParent());
      _createSaoHoaBackground();
      _createRedDustSpawner();
      _createMonsterSpawner();
    }

    _createPickupSpawner();
  }

  void _removeSpawners() {
    _asteroidSpawner?.removeFromParent();
    _monsterSpawner?.removeFromParent();
    _pickupSpawner?.removeFromParent();
    _bubbleSpawner?.removeFromParent();
    _redDustSpawner?.removeFromParent();
    _asteroidSpawner = null;
    _monsterSpawner = null;
    _pickupSpawner = null;
    _bubbleSpawner = null;
    _redDustSpawner = null;
  }

  void _removeAllUI() {
    joystick.removeFromParent();
    _shootButton?.removeFromParent();
    _shootButton = null;
    _scoreDisplay?.removeFromParent();
    _scoreDisplay = null;
    _healthDisplay?.removeFromParent();
    _healthDisplay = null;
    _distanceDisplay?.removeFromParent();
    _distanceDisplay = null;
    _progressBar?.removeFromParent();
    _progressBar = null;
    _progressFill?.removeFromParent();
    _progressFill = null;
    _shieldIcon?.removeFromParent();
    _shieldIcon = null;
    _laserIcon?.removeFromParent();
    _laserIcon = null;
    _menuBtn?.removeFromParent();
    _menuBtn = null;
  }

  void _stopAllSpawners() {
    _asteroidSpawner?.timer.stop();
    _monsterSpawner?.timer.stop();
    _pickupSpawner?.timer.stop();
    _bubbleSpawner?.timer.stop();
    _redDustSpawner?.timer.stop();
  }

  void _startLevelTransition() {
    if (_levelTransitioning) return;
    _levelTransitioning = true;
    
    player.stopShooting();
    _stopAllSpawners();
    _removeAllUI();

    player.add(
      MoveToEffect(
        Vector2(size.x / 2, -player.size.y * 2),
        EffectController(duration: 0.5, curve: Curves.easeIn),
        onComplete: _playTransitionSequence,
      ),
    );
  }

  void _playTransitionSequence() {
    final blackOverlay = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black,
      priority: 1000,
    )..opacity = 0;
    add(blackOverlay);

    blackOverlay.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 0.5, curve: Curves.easeOut),
        onComplete: () {
           currentLevel++; 
           _setupLevel();
           
           blackOverlay.add(
             OpacityEffect.to(
               0.0,
               EffectController(duration: 1.0, curve: Curves.easeIn, startDelay: 0.5),
               onComplete: () {
                 blackOverlay.removeFromParent();
                 _bringPlayerBack();
               }
             )
           );
        }
      )
    );
  }

  void _bringPlayerBack() {
    player.position = Vector2(size.x / 2, size.y + player.size.y * 2);
    player.opacity = 0;
    
    player.addAll([
      MoveToEffect(
        Vector2(size.x / 2, size.y * 0.80),
        EffectController(duration: 0.5, curve: Curves.easeOutBack),
        onComplete: () {
          _levelTransitioning = false;
          _createUI();
        }
      ),
      OpacityEffect.fadeIn(
        EffectController(duration: 0.5, curve: Curves.easeIn),
      )
    ]);
  }

  void _createUI() {
    _createJoystick();
    _createShootButton();
    _createScoreDisplay(_safeTop);
    _createHealthDisplay(_safeTop);
    _createDistanceDisplay(_safeTop);
    _createProgressBar(_safeTop);
    _createPowerupsDisplay(_safeTop);
    _createPauseButton(_safeTop);
  }

  Future<void> _createPlayer() async {
    player = Player();
    player.position = Vector2(size.x / 2, size.y * 0.8);
    await add(player);
  }

  void _createJoystick() {
    joystick = JoystickComponent(
      knob: SpriteComponent(sprite: _joystickKnobSprite, size: Vector2.all(50)),
      background: SpriteComponent(sprite: _joystickBackgroundSprite, size: Vector2.all(100)),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, size.y - 20),
      priority: 100,
    );
    add(joystick);
  }

  void _createShootButton() {
    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 20, size.y - 20)
      ..priority = 100;
    add(_shootButton!);
  }

  void _createPauseButton(double topMargin) {
    _menuBtn = HamburgerMenuComponent(
      position: Vector2(size.x - 30, topMargin + 30),
      onPressed: pauseGame,
    );
    add(_menuBtn!);
  }

  void pauseGame() {
    pauseEngine();
    overlays.add('PauseMenu');
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(position: _generateSpawnPosition()),
      minPeriod: 0.7,
      maxPeriod: 1.2,
      autoStart: true,
    );
    add(_asteroidSpawner!);
  }

  void _createMonsterSpawner() {
    _monsterSpawner = SpawnComponent.periodRange(
      factory: (index) => Monster(position: _generateSpawnPosition()),
      minPeriod: 1.5,
      maxPeriod: 2.5,
      autoStart: true,
    );
    add(_monsterSpawner!);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(
        pickupType: PickupType.values[_random.nextInt(PickupType.values.length)],
        position: _generateSpawnPosition(),
      ),
      minPeriod: 10.0,
      maxPeriod: 20.0,
      autoStart: true,
    );
    add(_pickupSpawner!);
  }

  void _createBubbleSpawner() {
    _bubbleSpawner = SpawnComponent.periodRange(
      factory: (index) => Bubble(),
      minPeriod: 0.1,
      maxPeriod: 0.3,
      autoStart: true,
      selfPositioning: true, 
    );
    add(_bubbleSpawner!);
  }
  
  void _createRedDustSpawner() {
    _redDustSpawner = SpawnComponent.periodRange(
        factory: (index) => RedDust(),
        minPeriod: 0.2,
        maxPeriod: 0.5,
        autoStart: true);
    add(_redDustSpawner!);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(_random.nextDouble() * size.x, -150);
  }
  
  void _createSaoThuyBackground() async {
    _background = SpriteComponent(
      sprite: await loadSprite('sao_thuy.png'),
      size: size,
      priority: -100,
    );
    add(_background!);
  }
  
  void _createSaoHoaBackground() async {
    _background = SpriteComponent(
      sprite: await loadSprite('sao_hoa.png'),
      size: size,
      priority: -100,
    );
    add(_background!);
  }

  void _createStars() {
    if (children.whereType<Star>().isEmpty) {
        for (int i = 0; i < 50; i++) {
          add(Star()..priority = -10);
        }
    }
  }

  void _createScoreDisplay(double topMargin) {
    _scoreDisplay = TextComponent(
      text: '$_score',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, topMargin + 5),
      priority: 10,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2)])),
    );
    add(_scoreDisplay!);
  }

  void _createHealthDisplay(double topMargin) {
    final hearts = ''.padRight(player.lives, '❤️');
    _healthDisplay = TextComponent(
      text: hearts,
      anchor: Anchor.topLeft,
      position: Vector2(20, topMargin + 5),
      priority: 10,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 30, shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2)])),
    );
    add(_healthDisplay!);
  }

  void updatePlayerHealth(int lives) {
    if (_healthDisplay == null) return;
    final hearts = ''.padRight(lives, '❤️');
    _healthDisplay!.text = hearts;
  }

  void _createDistanceDisplay(double topMargin) {
    _distanceDisplay = TextComponent(
      text: '${_distanceTraveled.toInt()} km',
      anchor: Anchor.topLeft,
      position: Vector2(40, topMargin + 80),
      priority: 10,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)])),
    );
    add(_distanceDisplay!);
  }

  void _createProgressBar(double topMargin) {
    _progressBar = RectangleComponent(size: Vector2(10, 200), position: Vector2(20, topMargin + 80), paint: Paint()..color = Colors.grey.withOpacity(0.5), priority: 9);
    add(_progressBar!);
    final progress = (_distanceTraveled > _levelTargets[0])
        ? (_distanceTraveled - _levelTargets[0]) / (_levelTargets[1] - _levelTargets[0])
        : _distanceTraveled / _levelTargets[0];
    _progressFill = RectangleComponent(size: Vector2(10, 200 * progress), position: Vector2(20, topMargin + 280), anchor: Anchor.bottomLeft, paint: Paint()..color = Colors.greenAccent, priority: 10);
    add(_progressFill!);
  }

  void _createPowerupsDisplay(double topMargin) {
    _shieldIcon = SpriteComponent(
      sprite: _shieldIconSprite,
      size: Vector2.all(40),
      anchor: Anchor.topRight,
      position: Vector2(size.x - 20, topMargin + 80),
      priority: 10,
    )..opacity = player.hasShield ? 1 : 0;

    _laserIcon = SpriteComponent(
      sprite: _laserIconSprite,
      size: Vector2.all(40),
      anchor: Anchor.topRight,
      position: Vector2(size.x - 20, topMargin + 130),
      priority: 10,
    )..opacity = player.isLaserActive ? 1 : 0;

    add(_shieldIcon!);
    add(_laserIcon!);
  }

  void incrementScore(int amount) {
    if (_levelTransitioning || _scoreDisplay == null) return;
    _score += amount;
    _scoreDisplay!.text = _score.toString();
    _scoreDisplay!.add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.05, alternate: true)));
  }

  void playerDied() {
    overlays.add('GameOver');
    pauseEngine();
  }

  void restartGame() {
    _levelTransitioning = false;
    _distanceTraveled = 0.0;
    currentLevel = 1;
    _score = 0;
    
    // Remove all game components except for the essentials
    children.where((c) => c is! CameraComponent && c is! AudioManager).forEach(remove);

    _createStars();
    startGame();
    resumeEngine();
  }

  void quitGame() {
    children.where((c) => c is! CameraComponent && c is! AudioManager && c is! Star).forEach(remove);
    
    if (children.whereType<Star>().isEmpty) {
        _createStars();
    }

    overlays.add('Title');
    resumeEngine();
  }
}

class HamburgerMenuComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  HamburgerMenuComponent({required super.position, required this.onPressed}) : super(size: Vector2(40, 30), anchor: Anchor.center, priority: 20);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    const lineHeight = 4.0;
    const gap = 6.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, lineHeight), paint);
    canvas.drawRect(Rect.fromLTWH(0, lineHeight + gap, width, lineHeight), paint);
    canvas.drawRect(Rect.fromLTWH(0, (lineHeight + gap) * 2, width, lineHeight), paint);
  }

  @override
  void onTapDown(TapDownEvent event) => onPressed();
}
