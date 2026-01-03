import 'dart:async';
import 'dart:math';

import 'package:Phoenix_Blast/components/asteroid.dart';
import 'package:Phoenix_Blast/components/audio_manager.dart';
import 'package:Phoenix_Blast/components/boss_monster.dart';
import 'package:Phoenix_Blast/components/bubble.dart';
import 'package:Phoenix_Blast/components/coin.dart';
import 'package:Phoenix_Blast/components/monster.dart';
import 'package:Phoenix_Blast/components/monster_laser.dart';
import 'package:Phoenix_Blast/components/laser.dart';
import 'package:Phoenix_Blast/components/red_laser.dart';
import 'package:Phoenix_Blast/components/pickup.dart';
import 'package:Phoenix_Blast/components/player.dart';
import 'package:Phoenix_Blast/components/red_dust.dart';
import 'package:Phoenix_Blast/components/shoot_button.dart';
import 'package:Phoenix_Blast/components/star.dart';
import 'package:Phoenix_Blast/components/explosion.dart';
import 'package:Phoenix_Blast/services/firebase_service.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  final Random _random = Random();
  ShootButton? _shootButton;

  String currentSkin = 'vang';
  String currentSkill = '';
  List<String> skinsOwned = ['vang', 'maybay'];

  late Sprite _joystickKnobSprite;
  late Sprite _joystickBackgroundSprite;
  late Sprite _shieldIconSprite;
  late Sprite _laserIconSprite;
  late Sprite _coinSprite;

  SpawnComponent? _asteroidSpawner;
  SpawnComponent? _bubbleSpawner;
  SpawnComponent? _redDustSpawner;

  double _monsterSpawnTimer = 0;

  int currentLevel = 1;
  bool _levelTransitioning = false;
  bool _bossSpawned = false;
  bool _isGameEnded = false;
  bool _waitingForVictoryCoins = false;
  int _victoryCoinCount = 0;
  SpriteComponent? _background;

  double _distanceTraveled = 0.0;
  double get distanceTraveled => _distanceTraveled;
  final List<double> _levelTargets = [12000.0, 30000.0, 50000.0];
  final int _maxLevel = 3;
  final double _speedKmPerSecond = 400.0;

  TextComponent? _distanceDisplay;
  RectangleComponent? _progressBar;
  RectangleComponent? _progressFill;
  TextComponent? _healthDisplay;
  TextComponent? _nicknameDisplay;
  TextComponent? _sessionCoinDisplay;
  SpriteComponent? _coinIcon;
  SpriteComponent? _shieldIcon;
  SpriteComponent? _laserIcon;
  TextComponent? _scoreDisplay;
  HamburgerMenuComponent? _menuBtn;
  int _score = 0;
  int _totalCoins = 0;
  int _sessionCoins = 0;

  String? _nickname;
  String? get nickname => _nickname;
  int get totalCoins => _totalCoins;
  int get sessionCoins => _sessionCoins;

  int get score => _score;

  late final AudioManager audioManager;
  late final double _safeTop;

  final FirebaseService _firebaseService = FirebaseService();
  bool isOnline = false;
  final ValueNotifier<String?> nicknameNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isSavingScore = ValueNotifier(false);

  @override
  Future<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    await images.loadAll([
      'joystick_knob.png',
      'joystick_background.png',
      'shield_pickup.png',
      'laser_pickup.png',
      'bomb_pickup.png',
      'heart_pickup.png',
      'laser.png',
      'tiatim.png',
      'tiaxanh.png',
      'asteroid1.png',
      'asteroid2.png',
      'asteroid3.png',
      'monster_saothuy1.png',
      'monster_saothuy1.1.png',
      'monster_saothuy3.png',
      'monster_saothuy3.1.png',
      'monster_saothuy3.2.png',
      'monster_mini_sao_hoa_1.png',
      'monster_mini_sao_hoa_1.1.png',
      'monster_mini_sao_hoa_1.2.png',
      'monster_mini_sao_hoa_2.png',
      'monster_mini_sao_hoa_2.1.png',
      'sao_thuy.png',
      'sao_hoa.png',
      'title.png',
      'start_button.png',
      'arrow_button.png',
      'vang.png',
      'vang1.png',
      'vang2.png',
      'vang3.png',
      'maybay.png',
      'maybay1.png',
      'maybay2.png',
      'player_red_off.png',
      'player_red_on0.png',
      'player_red_on1.png',
      'player_blue_off.png',
      'player_blue_on0.png',
      'player_blue_on1.png',
      'chienco_hong.png',
      'chienco_hong1.png',
      'chienco_hong2.png',
      'chienco_xanh.png',
      'chienco_xanh1.png',
      'chienco_xanh2.png',
      'skill_samxet.png',
      'skill_hinhtron.png',
      'skill_cauvong.png',
      'coin.png',
      'coin1.png',
      'coin2.png',
      'coin3.png',
    ]);

    _joystickKnobSprite = Sprite(images.fromCache('joystick_knob.png'));
    _joystickBackgroundSprite =
        Sprite(images.fromCache('joystick_background.png'));
    _shieldIconSprite = Sprite(images.fromCache('shield_pickup.png'));
    _laserIconSprite = Sprite(images.fromCache('laser_pickup.png'));
    _coinSprite = Sprite(images.fromCache('coin.png'));

    _safeTop = WidgetsBinding.instance.window.padding.top /
        WidgetsBinding.instance.window.devicePixelRatio;

    audioManager = AudioManager();
    await add(audioManager);
    audioManager.playMusic();
    _createStars();

    _handleInitialScreen();
  }

  void _handleInitialScreen() {
    overlays.add('Login');
    overlays.remove('Loading');
  }

  void onLoginSuccess() async {
    isOnline = true;
    overlays.remove('Login');
    overlays.add('Loading');

    if (_firebaseService.currentUser != null) {
      await _firebaseService.ensurePlayerDoc(_firebaseService.currentUser!);
    }

    await updatePlayerData();
    
    if (_nickname?.isNotEmpty == true) {
      overlays.remove('Loading');
      showMainMenu();
    } else {
      overlays.remove('Loading');
      overlays.add('Nickname');
    }
  }

  Future<void> updatePlayerData() async {
    final playerData = await _firebaseService.getPlayerData();
    if (playerData != null) {
      _nickname = playerData['nickname'];
      _totalCoins = (playerData['coins'] ?? 0) as int;
      currentSkin = playerData['currentSkin'] ?? 'vang';
      currentSkill = playerData['currentSkill'] ?? '';
      skinsOwned = (playerData['skinsOwned'] as Map<String, dynamic>).keys.toList();
      nicknameNotifier.value = _nickname;
    }
  }

  Future<void> setNickname(String newNickname) async {
    _nickname = newNickname;
    nicknameNotifier.value = _nickname;
    if (isOnline) {
      await _firebaseService.setNickname(newNickname);
    }
  }

  void startOffline() {
    isOnline = false;
    _nickname = 'Offline';
    nicknameNotifier.value = _nickname;
    _totalCoins = 0;
    currentSkin = 'vang';
    currentSkill = '';
    skinsOwned = ['vang', 'maybay'];
    overlays.remove('Login');
    showMainMenu();
  }

  void showMainMenu() {
    overlays.remove('Nickname');
    overlays.remove('Leaderboard');
    overlays.remove('Login');
    overlays.remove('Loading');
    overlays.add('Title');
  }

  void showLeaderboard() {
    overlays.remove('Title');
    overlays.add('Leaderboard');
  }

  void logout() async {
    if (isOnline) {
      await _firebaseService.signOut();
      isOnline = false;
    }
    _nickname = null;
    nicknameNotifier.value = null;
    _nicknameDisplay = null;
    _totalCoins = 0;
    _sessionCoins = 0;
    overlays.clear();
    overlays.add('Login');
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (children.whereType<Player>().isNotEmpty && player.isMounted) {
      _updatePowerupsDisplay();

      if (!_levelTransitioning) {
        _distanceTraveled += _speedKmPerSecond * dt;

        _handleMonsterSpawning(dt);

        if (currentLevel == 3 && _distanceTraveled >= 50000 && !_bossSpawned) {
          _triggerBossEvent();
        }

        double currentTarget = (_levelTargets.length >= currentLevel)
            ? _levelTargets[currentLevel - 1]
            : double.infinity;
        double progressBase =
            (currentLevel > 1) ? _levelTargets[currentLevel - 2] : 0;
        double levelDistance = currentTarget - progressBase;

        if (_distanceDisplay != null && _progressFill != null) {
          double progress = (levelDistance > 0)
              ? (_distanceTraveled - progressBase) / levelDistance
              : 0.0;
          _progressFill!.size = Vector2(10, 200 * progress.clamp(0, 1));
          _distanceDisplay!.text = '${_distanceTraveled.toInt()} km';
        }

        if (currentLevel < _maxLevel && _distanceTraveled >= currentTarget) {
          if (currentLevel == 3 && !_bossSpawned) {
             // Do not transition, wait for boss to be defeated.
          } else {
            _distanceTraveled = currentTarget;
            _startLevelTransition();
          }
        }
      }
    }
  }

  void _handleMonsterSpawning(double dt) {
    if (currentLevel < 2 || _bossSpawned) return;

    _monsterSpawnTimer -= dt;
    if (_monsterSpawnTimer <= 0) {
      double spawnRate;
      if (currentLevel == 2) {
        if (_distanceTraveled < 20000) {
          spawnRate = 1.2 + _random.nextDouble() * 1.0;
        } else {
          spawnRate = 0.8 + _random.nextDouble() * 0.8;
        }
      } else if (currentLevel == 3) {
        // Điều chỉnh màn 3 xuất hiện cùng mức độ với màn 2
        if (_distanceTraveled < 40000) {
          spawnRate = 1.2 + _random.nextDouble() * 1.0;
        } else {
          spawnRate = 0.8 + _random.nextDouble() * 0.8;
        }
      } else {
        spawnRate = 0.8 + _random.nextDouble() * 1.0;
      }

      add(Monster(position: _generateSpawnPosition()));

      // Giảm tỷ lệ quái phụ ở màn 3 để giống màn 2 hơn
      if (currentLevel == 3 && _random.nextDouble() < 0.1) { 
        add(Monster(position: _generateSpawnPosition()));
      }

      _monsterSpawnTimer = spawnRate;
    }
  }

  void _triggerBossEvent() {
    _bossSpawned = true;
    _stopAllSpawners();
    children.whereType<Monster>().forEach((m) => m.explodeSilently());

    final alarmOverlay = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.red.withOpacity(0.3),
      priority: 100,
    );
    add(alarmOverlay);
    alarmOverlay.add(OpacityEffect.to(
        0.1, EffectController(duration: 0.5, reverseDuration: 0.5, repeatCount: 3),
        onComplete: () {
      alarmOverlay.removeFromParent();
      add(BossMonster(position: Vector2(size.x / 2, -150)));
    }));
  }

  void bossDefeated() {
    _waitingForVictoryCoins = true;
    _victoryCoinCount = 30;
    for (int i = 0; i < 30; i++) {
      final coin = Coin(
        value: 1, 
        position: Vector2(size.x / 2, size.y / 2),
        isVictoryCoin: true,
      );
      add(coin);
    }
  }

  void decrementVictoryCoinCount() {
    _victoryCoinCount--;
    if (_victoryCoinCount <= 0 && _waitingForVictoryCoins) {
      _waitingForVictoryCoins = false;
      victory();
    }
  }

  void victory() {
    if (_isGameEnded) return;
    _isGameEnded = true;

    if (player.isDestroyed) return;
    pauseEngine();
    overlays.add('Victory');

    if (isOnline) {
      isSavingScore.value = true;
      _firebaseService.onGameEnd(
        score: _score,
        coinsEarned: _sessionCoins,
      ).whenComplete(() {
        isSavingScore.value = false;
      });
    }
  }

  void _updatePowerupsDisplay() {
    if (_shieldIcon == null || _laserIcon == null) return;
    _shieldIcon!.opacity = player.hasShield ? 1 : 0;
    if (!player.isLaserActive) {
      _laserIcon!.opacity = 0;
    } else {
      _laserIcon!.opacity = (player.laserRemainingTime < 3.0)
          ? (sin(player.laserRemainingTime * 10) + 1) / 2
          : 1.0;
    }
  }

  Future<void> startGame() async {
    _isGameEnded = false;
    currentLevel = 1;
    _distanceTraveled = 0.0;
    _levelTransitioning = false;
    _bossSpawned = false;
    _monsterSpawnTimer = 0;
    _score = 0;
    _sessionCoins = 0;
    await _createPlayer();
    _createUI();
    _setupLevel();
  }

  void _setupLevel() {
    children
        .where((c) =>
            c is Asteroid ||
            c is Monster ||
            c is BossMonster ||
            c is Bubble ||
            c is RedDust ||
            c is Pickup ||
            c is MonsterLaser ||
            c is Laser ||
            c is RedLaser ||
            c is Explosion ||
            c is Coin ||
            (c is RectangleComponent && c.priority == 100) ||
            c is BombExplosion)
        .forEach((c) => c.removeFromParent());

    if (currentLevel > 1) {
      children.whereType<Star>().forEach((s) => s.removeFromParent());
    }

    _background?.removeFromParent();
    _background = null;
    _removeSpawners();

    if (currentLevel == 1) {
      if (children.whereType<Star>().isEmpty) _createStars();
      _createAsteroidSpawner();
    } else if (currentLevel == 2) {
      _createSaoThuyBackground();
      _createBubbleSpawner();
    } else if (currentLevel == 3) {
      _createSaoHoaBackground();
      _createRedDustSpawner();
    }
  }

  void _removeSpawners() {
    _asteroidSpawner?.removeFromParent();
    _bubbleSpawner?.removeFromParent();
    _redDustSpawner?.removeFromParent();
    _asteroidSpawner = null;
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
    _nicknameDisplay?.removeFromParent();
    _nicknameDisplay = null;
    _sessionCoinDisplay?.removeFromParent();
    _sessionCoinDisplay = null;
    _coinIcon?.removeFromParent();
    _coinIcon = null;
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
  }

  void _startLevelTransition() {
    if (_levelTransitioning) return;
    _levelTransitioning = true;
    player.isTransitioning = true;
    player.stopShooting();
    _stopAllSpawners();
    _removeAllUI();
    player.add(MoveToEffect(Vector2(size.x / 2, -player.size.y * 2),
        EffectController(duration: 0.5, curve: Curves.easeIn),
        onComplete: _playTransitionSequence));
  }

  void _playTransitionSequence() {
    final blackOverlay = RectangleComponent(
        size: size, paint: Paint()..color = Colors.black, priority: 1000)
      ..opacity = 0;
    add(blackOverlay);
    blackOverlay.add(OpacityEffect.to(
        1.0, EffectController(duration: 0.5, curve: Curves.easeOut),
        onComplete: () {
      currentLevel++;
      _setupLevel();
      blackOverlay.add(OpacityEffect.to(
          0.0,
          EffectController(
              duration: 1.0, curve: Curves.easeIn, startDelay: 0.5),
          onComplete: () {
        blackOverlay.removeFromParent();
        _bringPlayerBack();
      }));
    }));
  }

  void _bringPlayerBack() {
    final currentLives = player.lives;
    player.removeFromParent(); 
    _createPlayer(lives: currentLives);
    player.position = Vector2(size.x / 2, size.y + player.size.y * 2);
    player.opacity = 0;
    player.addAll([
      MoveToEffect(
          Vector2(size.x / 2, size.y * 0.80),
          EffectController(duration: 0.5, curve: Curves.easeOutBack),
          onComplete: () {
        _levelTransitioning = false;
        player.isTransitioning = false;
        _createUI();
      }),
      OpacityEffect.fadeIn(
          EffectController(duration: 0.5, curve: Curves.easeIn))
    ]);
  }

  void _createUI() {
    _createJoystick();
    _createShootButton();
    _createScoreDisplay(_safeTop);
    _createHealthDisplay(_safeTop);
    if (isOnline) _createNicknameDisplay(_safeTop);
    _createCoinDisplay(_safeTop);
    _createDistanceDisplay(_safeTop);
    _createProgressBar(_safeTop);
    _createPowerupsDisplay(_safeTop);
    _createPauseButton(_safeTop);
  }

  Future<void> _createPlayer({int? lives}) async {
    player = Player(
      skin: currentSkin,
      lives: lives,
      currentSkill: currentSkill,
    );
    player.position = Vector2(size.x / 2, size.y * 0.8);
    await add(player);
  }

  void _createJoystick() {
    joystick = JoystickComponent(
      knob: SpriteComponent(sprite: _joystickKnobSprite, size: Vector2.all(50)),
      background: SpriteComponent(
          sprite: _joystickBackgroundSprite, size: Vector2.all(100)),
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
        position: Vector2(size.x - 30, topMargin + 30), onPressed: pauseGame);
    add(_menuBtn!);
  }

  void pauseGame() {
    pauseEngine();
    overlays.add('PauseMenu');
  }

  void resumeGame() {
    overlays.remove('PauseMenu');
    resumeEngine();
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
        factory: (index) => Asteroid(position: _generateSpawnPosition()),
        minPeriod: 0.7,
        maxPeriod: 1.2,
        autoStart: true);
    add(_asteroidSpawner!);
  }

  void _createBubbleSpawner() {
    _bubbleSpawner = SpawnComponent.periodRange(
        factory: (index) => Bubble(),
        minPeriod: 0.5,
        maxPeriod: 1.0,
        autoStart: true,
        selfPositioning: true);
    add(_bubbleSpawner!);
  }

  void _createRedDustSpawner() {
    _redDustSpawner = SpawnComponent.periodRange(
        factory: (index) => RedDust(),
        minPeriod: 1.5,
        maxPeriod: 2.5,
        autoStart: true);
    add(_redDustSpawner!);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(
        _random.nextDouble() * size.x, -150 - _random.nextDouble() * 200);
  }

  void _createSaoThuyBackground() async {
    _background = SpriteComponent(
        sprite: Sprite(images.fromCache('sao_thuy.png')),
        size: size,
        priority: -100);
    add(_background!);
  }

  void _createSaoHoaBackground() async {
    _background = SpriteComponent(
        sprite: Sprite(images.fromCache('sao_hoa.png')),
        size: size,
        priority: -100);
    add(_background!);
  }

  void _createStars() {
    if (children.whereType<Star>().isEmpty) {
      for (int i = 0; i < 30; i++) {
        add(Star()..priority = -10);
      }
    }
  }

  void _createNicknameDisplay(double topMargin) {
    if (_nickname != null) {
      _nicknameDisplay = TextComponent(
          text: _nickname!,
          anchor: Anchor.topLeft,
          position: Vector2(20, topMargin + 5),
          priority: 10,
          textRenderer: TextPaint(
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)
              ])));
      add(_nicknameDisplay!);
    }
  }

  void _createScoreDisplay(double topMargin) {
    _scoreDisplay = TextComponent(
        text: '$_score',
        anchor: Anchor.topCenter,
        position: Vector2(size.x / 2, topMargin + 5),
        priority: 10,
        textRenderer: TextPaint(
            style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
              Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2)
            ])));
    add(_scoreDisplay!);
  }

  void _createHealthDisplay(double topMargin) {
    String healthText;
    if (player.lives > 3) {
      healthText = '❤️x${player.lives}';
    } else {
      healthText = ''.padRight(player.lives, '❤️');
    }
    _healthDisplay = TextComponent(
        text: healthText,
        anchor: Anchor.topLeft,
        position: Vector2(20, topMargin + 25),
        priority: 10,
        textRenderer: TextPaint(
            style: const TextStyle(fontSize: 30, shadows: [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2)
        ])));
    add(_healthDisplay!);
  }

  void _createCoinDisplay(double topMargin) {
    _coinIcon = SpriteComponent(
        sprite: _coinSprite,
        size: Vector2.all(25),
        anchor: Anchor.topLeft,
        position: Vector2(20, topMargin + 60),
        priority: 10);
    add(_coinIcon!);

    _sessionCoinDisplay = TextComponent(
        text: 'x$_sessionCoins',
        anchor: Anchor.topLeft,
        position: Vector2(50, topMargin + 62),
        priority: 10,
        textRenderer: TextPaint(
            style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)
            ])));
    add(_sessionCoinDisplay!);
  }

  void updatePlayerHealth(int lives) {
    if (_healthDisplay != null) {
      if (lives > 3) {
        _healthDisplay!.text = '❤️x$lives';
      } else {
        _healthDisplay!.text = ''.padRight(lives, '❤️');
      }
    }
  }

  void _createDistanceDisplay(double topMargin) {
    _distanceDisplay = TextComponent(
        text: '${_distanceTraveled.toInt()} km',
        anchor: Anchor.topLeft,
        position: Vector2(20, topMargin + 90), 
        priority: 10,
        textRenderer: TextPaint(
            style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)
            ])));
    add(_distanceDisplay!);
  }

  void _createProgressBar(double topMargin) {
    _progressBar = RectangleComponent(
        size: Vector2(10, 200),
        position: Vector2(20, topMargin + 120), 
        paint: Paint()..color = Colors.grey.withOpacity(0.5),
        priority: 9);
    add(_progressBar!);
    _progressFill = RectangleComponent(
        size: Vector2(10, 0),
        position: Vector2(20, topMargin + 320), 
        anchor: Anchor.bottomLeft,
        paint: Paint()..color = Colors.greenAccent,
        priority: 10);
    add(_progressFill!);
  }

  void _createPowerupsDisplay(double topMargin) {
    _shieldIcon = SpriteComponent(
        sprite: _shieldIconSprite,
        size: Vector2.all(40),
        anchor: Anchor.topRight,
        position: Vector2(size.x - 20, topMargin + 80),
        priority: 10)
      ..opacity = player.hasShield ? 1 : 0;
    _laserIcon = SpriteComponent(
        sprite: _laserIconSprite,
        size: Vector2.all(40),
        anchor: Anchor.topRight,
        position: Vector2(size.x - 20, topMargin + 130),
        priority: 10)
      ..opacity = player.isLaserActive ? 1 : 0;
    add(_shieldIcon!);
    add(_laserIcon!);
  }

  void addSessionCoins(int amount) {
    _sessionCoins += amount;
    _sessionCoinDisplay?.text = 'x$_sessionCoins';
  }

  Future<void> updateCurrentSkin(String skin) async {
    currentSkin = skin;
    if (isOnline) {
      await _firebaseService.equipItem(skin, 'skin');
    }
    await updatePlayerData();
  }

  Future<void> updateCurrentSkill(String skill) async {
    currentSkill = skill;
    if (isOnline) {
      await _firebaseService.equipItem(skill, 'skill');
    }
    await updatePlayerData();
  }

  void incrementScore(int amount) {
    if (_levelTransitioning || _scoreDisplay == null) return;
    _score += amount;
    _scoreDisplay!.text = _score.toString();
    _scoreDisplay!.add(
        ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.05, alternate: true)));
  }

  void playerDied() {
    if (_isGameEnded) return;
    _isGameEnded = true;

    pauseEngine();
    overlays.add('GameOver');

    if (isOnline) {
      isSavingScore.value = true;
      _firebaseService.onGameEnd(
        score: _score,
        coinsEarned: _sessionCoins,
      ).whenComplete(() {
        isSavingScore.value = false;
      });
    }
  }


  void restartGame() {
    if (isOnline) {
      // Reset online game
      _levelTransitioning = false;
      _distanceTraveled = 0.0;
      currentLevel = 1;
      _score = 0;
      _sessionCoins = 0;
      _bossSpawned = false;

      children.where((c) => c is! CameraComponent && c is! AudioManager).forEach((c) => c.removeFromParent());
      _createStars();
      startGame();
      resumeEngine();
    } else {
      // Reset offline game
      _levelTransitioning = false;
      _distanceTraveled = 0.0;
      currentLevel = 1;
      _score = 0;
      _sessionCoins = 0;
      _bossSpawned = false;

      children.where((c) => c is! CameraComponent && c is! AudioManager).forEach((c) => c.removeFromParent());
      _createStars();
      startOffline(); // Re-initialize offline settings
      startGame();
      resumeEngine();
    }
  }

  void quitGame() {
    if (isOnline) {
      updatePlayerData();
    }
    children
        .where((c) =>
            c is! CameraComponent && c is! AudioManager && c is! Star)
        .forEach((c) => c.removeFromParent());
    if (children.whereType<Star>().isEmpty) _createStars();
    showMainMenu();
    resumeEngine();
  }
}

class HamburgerMenuComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  HamburgerMenuComponent({required super.position, required this.onPressed})
      : super(size: Vector2(40, 30), anchor: Anchor.center, priority: 20);
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const lineHeight = 4.0;
    const gap = 6.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, lineHeight), paint);
    canvas.drawRect(Rect.fromLTWH(0, lineHeight + gap, width, lineHeight), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, (lineHeight + gap) * 2, width, lineHeight), paint);
  }

  @override
  void onTapDown(TapDownEvent event) => onPressed();
}
