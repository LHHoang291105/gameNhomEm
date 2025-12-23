import 'package:Phoenix_Blast/my_game.dart';
import 'package:Phoenix_Blast/overlays/countdown_overlay.dart';
import 'package:flutter/material.dart';

class PauseMenu extends StatefulWidget {
  final MyGame game;

  const PauseMenu({super.key, required this.game});

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(15.0), // Smaller padding
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 36, // Smaller font
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25), // Reduced height
              
              // Audio Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Music Toggle
                  Column(
                    children: [
                      const Text('Music', style: TextStyle(color: Colors.white, fontSize: 14)),
                      IconButton(
                        onPressed: () {
                          widget.game.audioManager.toggleMusic();
                          setState(() {}); // Rebuild widget to update icon
                        },
                        icon: Icon(
                          widget.game.audioManager.musicEnabled
                              ? Icons.music_note
                              : Icons.music_off,
                          color: widget.game.audioManager.musicEnabled
                              ? Colors.greenAccent
                              : Colors.grey,
                          size: 32, // Smaller icon
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 30),
                  // Sound Toggle
                  Column(
                    children: [
                      const Text('Sound', style: TextStyle(color: Colors.white, fontSize: 14)),
                      IconButton(
                        onPressed: () {
                          widget.game.audioManager.toggleSounds();
                          setState(() {}); // Rebuild widget to update icon
                        },
                        icon: Icon(
                          widget.game.audioManager.soundsEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: widget.game.audioManager.soundsEnabled
                              ? Colors.greenAccent
                              : Colors.grey,
                          size: 32, // Smaller icon
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25), // Reduced height

              // Resume Button
              SizedBox(
                width: 180, // Smaller width
                height: 45, // Smaller height
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    widget.game.overlays.remove('PauseMenu');
                    widget.game.overlays.add('Countdown');
                  },
                  child: const Text(
                    'RESUME',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15), // Reduced height

              // Quit Button
              SizedBox(
                width: 180, // Smaller width
                height: 45, // Smaller height
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () {
                    _showExitConfirmation(context);
                  },
                  child: const Text(
                    'QUIT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Thoát', // "Exit"
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Bạn có muốn thoát ?', // "Do you want to exit?"
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text('Không', style: TextStyle(color: Colors.blueAccent)), // "No"
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
            TextButton(
              child: const Text('Có', style: TextStyle(color: Colors.redAccent)), // "Yes"
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                widget.game.overlays.remove('PauseMenu');
                widget.game.quitGame(); // Quit game logic
              },
            ),
          ],
        );
      },
    );
  }
}
