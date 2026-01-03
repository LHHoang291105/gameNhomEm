import 'package:Phoenix_Blast/my_game.dart';
import 'package:flutter/material.dart';

class GiftCodeOverlay extends StatefulWidget {
  final MyGame game;

  const GiftCodeOverlay({super.key, required this.game});

  @override
  State<GiftCodeOverlay> createState() => _GiftCodeOverlayState();
}

class _GiftCodeOverlayState extends State<GiftCodeOverlay> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _redeemCode() async {
    if (_isLoading) return;

    final code = _controller.text.trim().toLowerCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã code.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final message = await widget.game.redeemGiftCode(code);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (message.startsWith('Chúc mừng')) {
        widget.game.updatePlayerData(); // Cập nhật lại số xu
        widget.game.overlays.remove('GiftCode');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.cyanAccent, width: 2),
          ),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhập Giftcode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_isLoading,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập mã tại đây...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                      ),
                      onPressed: () {
                        widget.game.overlays.remove('GiftCode');
                      },
                      child: const Text('Hủy', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                      ),
                      onPressed: _redeemCode,
                      child: const Text('Xác nhận', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
