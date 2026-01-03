import 'package:Phoenix_Blast/my_game.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class VictoryOverlay extends StatefulWidget {
  final MyGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Khởi tạo animation đập mạch (phóng to nhỏ) cho điểm số
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // Sử dụng reverse: true thay cho alternate
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // Hiệu ứng Ruy băng bắn từ 2 bên
          const _ConfettiParticles(isLeft: true),
          const _ConfettiParticles(isLeft: false),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'VICTORY!',
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.orange, blurRadius: 25, offset: Offset(0, 0)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Hiệu ứng điểm số phóng to thu nhỏ có hào quang
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.game.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                const SizedBox(height: 80),
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
                      _MenuButton(
                        text: 'CHƠI LẠI',
                        color: Colors.greenAccent,
                        onPressed: () {
                          widget.game.audioManager.playSound('click');
                          widget.game.overlays.remove('Victory');
                          widget.game.restartGame();
                        },
                      ),
                      const SizedBox(height: 20),
                      _MenuButton(
                        text: 'THOÁT',
                        color: Colors.redAccent,
                        onPressed: () {
                          widget.game.audioManager.playSound('click');
                          widget.game.overlays.remove('Victory');
                          widget.game.quitGame();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({required this.text, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ConfettiParticles extends StatelessWidget {
  final bool isLeft;
  const _ConfettiParticles({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
      child: SizedBox(
        width: 300,
        height: 600,
        child: Stack(
          children: List.generate(25, (index) {
            return _ConfettiPiece(
              color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
              delay: index * 150,
              isLeft: isLeft,
            );
          }),
        ),
      ),
    );
  }
}

class _ConfettiPiece extends StatefulWidget {
  final Color color;
  final int delay;
  final bool isLeft;
  const _ConfettiPiece({required this.color, required this.delay, required this.isLeft});

  @override
  State<_ConfettiPiece> createState() => _ConfettiPieceState();
}

class _ConfettiPieceState extends State<_ConfettiPiece> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _rotation = Random().nextDouble() * 2 * pi;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Tính toán chu kỳ dựa trên delay
        double t = (_controller.value + (widget.delay / 3000)) % 1.0;
        final random = Random(widget.delay);
        
        // Quỹ đạo bay vòng cung
        double x = widget.isLeft 
            ? (t * 400 * random.nextDouble())
            : (300 - t * 400 * random.nextDouble());
        
        double y = 600 - (sin(t * pi) * 500 * random.nextDouble()) - (t * 200);

        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: _rotation + t * 10,
            child: Container(
              width: 8 + random.nextDouble() * 8,
              height: 8 + random.nextDouble() * 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: random.nextBool() ? BoxShape.rectangle : BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
