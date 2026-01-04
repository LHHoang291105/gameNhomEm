import 'package:Phoenix_Blast/my_game.dart';
import 'package:flutter/material.dart';

enum GameOverAction { none, restart, quit }

class GameOverOverlay extends StatefulWidget {
  final MyGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  double _opacity = 0.0;
  GameOverAction _action = GameOverAction.none;

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(milliseconds: 0),
      () {
        if (mounted) {
          setState(() {
            _opacity = 1.0;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      onEnd: () {
        if (_opacity == 0.0) {
          widget.game.overlays.remove('GameOver');
          if (_action == GameOverAction.restart) {
            widget.game.restartGame();
          } else if (_action == GameOverAction.quit) {
            widget.game.quitGame();
          }
        }
      },
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      child: Container(
        color: Colors.black.withAlpha(150),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Hiển thị điểm số khi thua
            Text(
              'SCORE: ${widget.game.score}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/coin.png',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  'x${widget.game.sessionCoins}',
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ValueListenableBuilder<bool>(
              valueListenable: widget.game.isSavingScore,
              builder: (context, isSaving, child) {
                if (isSaving) {
                  return const CircularProgressIndicator();
                }
                return child!;
              },
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      widget.game.audioManager.playSound('click');
                      setState(() {
                        _action = GameOverAction.restart;
                        _opacity = 0.0;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      widget.game.audioManager.playSound('click');
                      setState(() {
                        _action = GameOverAction.quit;
                        _opacity = 0.0;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'QUIT GAME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
