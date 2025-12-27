import 'package:Phoenix_Blast/my_game.dart';
import 'package:flutter/material.dart';

class TitleOverlay extends StatefulWidget {
  final MyGame game;

  const TitleOverlay({super.key, required this.game});

  @override
  State<TitleOverlay> createState() => _TitleOverlayState();
}

class _TitleOverlayState extends State<TitleOverlay> {
  double _opacity = 0.0;
  final List<String> _playerSkins = [
    'vang',
    'maybay',
    'chienco_hong',
    'chienco_xanh',
    'player_blue_off',
    'player_red_off'
  ];
  late int _playerSkinIndex;

  @override
  void initState() {
    super.initState();
    _playerSkinIndex = _playerSkins.indexOf(widget.game.currentSkin);
    if (_playerSkinIndex == -1) _playerSkinIndex = 0;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String playerSkin = _playerSkins[_playerSkinIndex];
    final bool isOwned = widget.game.skinsOwned.contains(playerSkin);

    return AnimatedOpacity(
      onEnd: () {
        if (_opacity == 0.0) {
          widget.game.overlays.remove('Title');
        }
      },
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      child: Container(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            PositionImage(
              top: 50,
              left: 20,
              child: IconButton(
                onPressed: () {
                  widget.game.audioManager.playSound('click');
                  widget.game.logout();
                },
                icon: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                    Text(
                      'LOGOUT',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),

            PositionImage(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () {
                  widget.game.audioManager.playSound('click');
                  widget.game.overlays.add('Instructions');
                },
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
            
            Column(
              children: [
                const SizedBox(height: 60),
                SizedBox(
                  width: 270,
                  child: Image.asset('assets/images/title.png'),
                ),
                const SizedBox(height: 10),
                if (widget.game.isOnline && widget.game.nickname != null)
                  Text(
                    'Chào mừng, ${widget.game.nickname}!',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.game.audioManager.playSound('click');
                        setState(() {
                          _playerSkinIndex--;
                          if (_playerSkinIndex < 0) {
                            _playerSkinIndex = _playerSkins.length - 1;
                          }
                        });
                      },
                      child: Transform.flip(
                        flipX: true,
                        child: SizedBox(
                          width: 30,
                          child: Image.asset('assets/images/arrow_button.png'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Opacity(
                          opacity: isOwned ? 1.0 : 0.4,
                          child: Image.asset(
                            'assets/images/$playerSkin.png',
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        widget.game.audioManager.playSound('click');
                        setState(() {
                          _playerSkinIndex++;
                          if (_playerSkinIndex == _playerSkins.length) {
                            _playerSkinIndex = 0;
                          }
                        });
                      },
                      child: SizedBox(
                        width: 30,
                        child: Image.asset('assets/images/arrow_button.png'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    if (isOwned) {
                      widget.game.currentSkin = _playerSkins[_playerSkinIndex];
                      widget.game.audioManager.playSound('start');
                      widget.game.overlays.add('Countdown');
                      setState(() {
                        _opacity = 0.0;
                      });
                    }
                  },
                  child: Opacity(
                    opacity: isOwned ? 1.0 : 0.5,
                    child: SizedBox(
                      width: 200,
                      child: Image.asset('assets/images/start_button.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (widget.game.isOnline)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.game.audioManager.playSound('click');
                          widget.game.showLeaderboard();
                        },
                        child: const Text(
                          'Bảng Xếp Hạng',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 10, color: Colors.cyan)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          widget.game.audioManager.playSound('click');
                          widget.game.overlays.add('Shop');
                        },
                        child: const Text(
                          'Cửa Hàng',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.yellowAccent,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 10, color: Colors.yellow)],
                          ),
                        ),
                      ),
                    ],
                  ),

                Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                widget.game.audioManager.toggleMusic();
                              });
                            },
                            icon: Icon(
                              widget.game.audioManager.musicEnabled
                                  ? Icons.music_note_rounded
                                  : Icons.music_off_rounded,
                              color: widget.game.audioManager.musicEnabled
                                  ? Colors.white
                                  : Colors.grey,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                widget.game.audioManager.toggleSounds();
                              });
                            },
                            icon: Icon(
                              widget.game.audioManager.soundsEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: widget.game.audioManager.soundsEnabled
                                  ? Colors.white
                                  : Colors.grey,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PositionImage extends StatelessWidget {
  final double? top, right, bottom, left;
  final Widget child;

  const PositionImage({super.key, this.top, this.right, this.bottom, this.left, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(top: top, right: right, bottom: bottom, left: left, child: child);
  }
}
