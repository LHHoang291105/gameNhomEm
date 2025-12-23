import 'package:Phoenix_Blast/my_game.dart';
import 'package:flutter/material.dart';

class InstructionsOverlay extends StatelessWidget {
  final MyGame game;

  const InstructionsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          children: [
            const Text(
              'HƯỚNG DẪN CHƠI',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.cyanAccent),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _InstructionItem(icon: Icons.gamepad_rounded, text: 'Sử dụng Joystick bên trái để di chuyển phi thuyền.'),
                    _InstructionItem(icon: Icons.ads_click_rounded, text: 'Bấm nút bên phải để bắn đạn.'),
                    _InstructionItem(icon: Icons.shield_rounded, text: 'Nhặt KHIÊN để bảo vệ khỏi 1 lần va chạm.'),
                    _InstructionItem(icon: Icons.bolt_rounded, text: 'Nhặt TIA CHÙM để bắn ra 3 tia laser cùng lúc.'),
                    _InstructionItem(icon: Icons.brightness_7_rounded, text: 'Nhặt BOM để tiêu diệt tất cả kẻ địch trên màn hình.'),
                    _InstructionItem(icon: Icons.warning_amber_rounded, text: 'Hãy cẩn thận với Boss ở màn 3!'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => game.overlays.remove('Instructions'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              child: const Text('ĐÃ HIỂU', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
