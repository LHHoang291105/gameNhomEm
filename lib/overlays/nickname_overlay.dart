import 'package:flutter/material.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:Phoenix_Blast/services/firebase_service.dart';

class NicknameOverlay extends StatefulWidget {
  final MyGame game;

  const NicknameOverlay({super.key, required this.game});

  @override
  State<NicknameOverlay> createState() => _NicknameOverlayState();
}

class _NicknameOverlayState extends State<NicknameOverlay> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  void _saveNickname() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nickname.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _firebaseService.setNickname(_nicknameController.text);

    if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.game.showMainMenu();
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Đặt Nickname của bạn',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  labelStyle: TextStyle(color: Colors.white),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLength: 15,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _saveNickname,
                      child: const Text('Lưu và Bắt đầu'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
