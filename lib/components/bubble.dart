import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:cosmic_havoc/my_game.dart';

class Bubble extends SpriteComponent with HasGameReference<MyGame> {
  final Random _random = Random();
  late double _speed;

  Bubble() : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    // Sử dụng hình bong2.png có sẵn trong assets
    sprite = await game.loadSprite('bong2.png');
    
    // Kích thước ngẫu nhiên
    size = Vector2.all(10 + _random.nextDouble() * 20);
    
    // Tốc độ bay
    _speed = 100 + _random.nextDouble() * 100;

    // Xuất hiện ở phía trên màn hình (để bay xuống)
    position = Vector2(
      _random.nextDouble() * game.size.x,
      -size.y,
    );

    // Độ mờ ngẫu nhiên để tạo hiệu ứng chiều sâu
    opacity = 0.3 + _random.nextDouble() * 0.4;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Bay từ trên xuống dưới (tạo hiệu ứng máy bay đang lao đi)
    position.y += _speed * dt;

    // Xóa khi bong bóng ra khỏi màn hình dưới
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
}
