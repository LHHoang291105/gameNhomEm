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
  bool _imagesPrecached = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      for (final skinName in _playerSkins) {
        precacheImage(AssetImage('assets/images/$skinName.png'), context);
      }
      _imagesPrecached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String playerSkin = _playerSkins[_playerSkinIndex];
    final bool isOwned = widget.game.skinsOwned.contains(playerSkin);

    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final buttonWidth = screenWidth * 0.5;
      final arrowButtonWidth = screenWidth * 0.1;
      final shipDisplaySize = screenWidth * 0.25;

      return AnimatedOpacity(
        onEnd: () {
          if (_opacity == 0.0) {
            widget.game.overlays.remove('Title');
          }
        },
        opacity: _opacity,
        duration: const Duration(milliseconds: 500),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopRow(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          width: screenWidth * 0.7,
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
                        _buildShipSelector(arrowButtonWidth, shipDisplaySize, isOwned, playerSkin),
                        const SizedBox(height: 10),
                        _buildStartButton(isOwned, buttonWidth, playerSkin),
                        const SizedBox(height: 20),
                        if (widget.game.isOnline) _buildMenuButtons(),
                      ],
                    ),
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              widget.game.audioManager.playSound('click');
              widget.game.logout();
            },
            icon: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                Text('LOGOUT', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () {
                  widget.game.audioManager.playSound('click');
                  widget.game.overlays.add('Instructions');
                },
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              IconButton(
                onPressed: () {
                   widget.game.audioManager.playSound('click');
                   widget.game.overlays.add('GiftCode');
                },
                 icon: const Icon(Icons.card_giftcard, color: Colors.greenAccent, size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipSelector(double arrowButtonWidth, double shipDisplaySize, bool isOwned, String playerSkin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            widget.game.audioManager.playSound('click');
            setState(() {
              _playerSkinIndex = (_playerSkinIndex - 1 + _playerSkins.length) % _playerSkins.length;
            });
          },
          child: Transform.flip(
            flipX: true,
            child: SizedBox(
              width: arrowButtonWidth,
              child: Image.asset('assets/images/arrow_button.png'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SizedBox(
            width: shipDisplaySize,
            height: shipDisplaySize,
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
              _playerSkinIndex = (_playerSkinIndex + 1) % _playerSkins.length;
            });
          },
          child: SizedBox(
            width: arrowButtonWidth,
            child: Image.asset('assets/images/arrow_button.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(bool isOwned, double buttonWidth, String playerSkin) {
    return GestureDetector(
      onTap: () async {
        if (isOwned) {
          if (widget.game.currentSkin != playerSkin) {
            await widget.game.updateCurrentSkin(playerSkin);
          }
          widget.game.audioManager.playSound('start');
          widget.game.overlays.add('Countdown');
          if (mounted) {
            setState(() {
              _opacity = 0.0;
            });
          }
        }
      },
      child: Opacity(
        opacity: isOwned ? 1.0 : 0.5,
        child: SizedBox(
          width: buttonWidth,
          child: Image.asset('assets/images/start_button.png'),
        ),
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Row(
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
    );
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  widget.game.audioManager.toggleMusic();
                });
              },
              icon: Icon(
                widget.game.audioManager.musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                color: widget.game.audioManager.musicEnabled ? Colors.white : Colors.grey,
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
                widget.game.audioManager.soundsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: widget.game.audioManager.soundsEnabled ? Colors.white : Colors.grey,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
