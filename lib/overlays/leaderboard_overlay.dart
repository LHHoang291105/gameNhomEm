import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:Phoenix_Blast/services/firebase_service.dart';

class LeaderboardOverlay extends StatelessWidget {
  final MyGame game;
  final FirebaseService _firebaseService = FirebaseService();

  LeaderboardOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
          child: Column(
            children: [
              Text(
                'Bảng Xếp Hạng',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 20, color: Colors.cyanAccent)],
                ),
              ),
              SizedBox(height: 40),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.getTopScores(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có ai trên bảng xếp hạng.',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    final scores = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: scores.length,
                      itemBuilder: (context, index) {
                        var scoreData = scores[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: Text(
                            '#${index + 1}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                          title: Text(
                            scoreData['nickname'] ?? 'Ẩn danh',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            scoreData['score'].toString(),
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('Leaderboard');
                  game.showMainMenu(); 
                },
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
