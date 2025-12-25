import 'package:Phoenix_Blast/my_game.dart';
import 'package:Phoenix_Blast/overlays/game_over_overlay.dart';
import 'package:Phoenix_Blast/overlays/leaderboard_overlay.dart';
import 'package:Phoenix_Blast/overlays/loading_overlay.dart'; // Import màn hình chờ
import 'package:Phoenix_Blast/overlays/login_overlay.dart';
import 'package:Phoenix_Blast/overlays/nickname_overlay.dart';
import 'package:Phoenix_Blast/overlays/shop_overlay.dart';
import 'package:Phoenix_Blast/overlays/title_overlay.dart';
import 'package:Phoenix_Blast/overlays/pause_menu.dart';
import 'package:Phoenix_Blast/overlays/countdown_overlay.dart';
import 'package:Phoenix_Blast/overlays/instructions_overlay.dart';
import 'package:Phoenix_Blast/overlays/victory_overlay.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final MyGame game = MyGame();

  runApp(
    MaterialApp(
      title: 'Phoenix Blast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
      ),
      home: Scaffold(
        body: GameWidget(
          game: game,
          initialActiveOverlays: const ['Loading'], 
          overlayBuilderMap: {
            'Loading': (context, MyGame game) => const LoadingOverlay(), 
            'GameOver': (context, MyGame game) => GameOverOverlay(game: game),
            'Title': (context, MyGame game) => TitleOverlay(game: game),
            'PauseMenu': (context, MyGame game) => PauseMenu(game: game),
            'Countdown': (context, MyGame game) => CountdownOverlay(game: game),
            'Instructions': (context, MyGame game) => InstructionsOverlay(game: game),
            'Victory': (context, MyGame game) => VictoryOverlay(game: game),
            'Login': (context, MyGame game) => LoginOverlay(game: game),
            'Nickname': (context, MyGame game) => NicknameOverlay(game: game),
            'Leaderboard': (context, MyGame game) => LeaderboardOverlay(game: game),
            'Shop': (context, MyGame game) => ShopOverlay(game: game),
          },
        ),
      ),
    ),
  );
}
