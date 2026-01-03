import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';

class AudioManager extends Component {
  bool musicEnabled = true;
  bool soundsEnabled = true;

  final Map<String, AudioPool> _pools = {};

  final List<String> _sounds = [
    'click',
    'collect',
    'explode1',
    'explode2',
    'fire',
    'hit',
    'laser',
    'start',
  ];

  @override
  FutureOr<void> onLoad() async {
    FlameAudio.bgm.initialize();

    // Preload sound effects
    final soundFiles = _sounds.map((s) => '$s.ogg').toList();
    await FlameAudio.audioCache.loadAll(soundFiles);

    // Initialize AudioPools for high-frequency sounds
    for (final sound in ['laser', 'explode1', 'explode2', 'hit']) {
      _pools[sound] = await FlameAudio.createPool(
        '$sound.ogg',
        minPlayers: 1,
        maxPlayers: 4,
      );
    }

    return super.onLoad();
  }

  void playMusic() {
    if (musicEnabled) {
      FlameAudio.bgm.play('music.ogg');
    }
  }

  void playSound(String sound) {
    if (soundsEnabled) {
      try {
        if (_pools.containsKey(sound)) {
          _pools[sound]!.start();
        } else {
          FlameAudio.play('$sound.ogg').catchError((e) {
             print("Audio Error ($sound): $e");
          });
        }
      } catch (e) {
        print("Audio Play Failed: $e");
      }
    }
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    if (musicEnabled) {
      playMusic();
    } else {
      FlameAudio.bgm.stop();
    }
  }

  void toggleSounds() {
    soundsEnabled = !soundsEnabled;
  }
}
