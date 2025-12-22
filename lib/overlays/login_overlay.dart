import 'package:flutter/material.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:cosmic_havoc/services/firebase_service.dart';

class LoginOverlay extends StatelessWidget {
  final MyGame game;
  final FirebaseService _firebaseService = FirebaseService();

  LoginOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder cho logo game của bạn
            Icon(Icons.rocket_launch, size: 100, color: Colors.cyanAccent),
            SizedBox(height: 20),
            Text(
              'Cosmic Havoc',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 20, color: Colors.cyanAccent)],
              ),
            ),
            SizedBox(height: 60),

            // Nút Đăng nhập Google
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, 
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final user = await _firebaseService.signInWithGoogle();
                if (user != null) {
                  game.onLoginSuccess();
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đăng nhập đã bị hủy hoặc thất bại.')),
                    );
                  }
                }
              },
              child: Text('Đăng nhập với Google'),
            ),
            SizedBox(height: 20),

            // Nút Chơi Offline
            TextButton(
              onPressed: () {
                game.startOffline();
              },
              child: Text(
                'Chơi Offline',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
