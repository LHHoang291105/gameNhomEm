import 'package:flutter/material.dart';
import 'package:Phoenix_Blast/my_game.dart';

class ShopOverlay extends StatefulWidget {
  final MyGame game;
  const ShopOverlay({super.key, required this.game});

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.cyanAccent, width: 2),
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[900]?.withOpacity(0.95),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () {
                        widget.game.overlays.remove('Shop');
                      },
                    ),
                    const Text(
                      'CỬA HÀNG',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10, color: Colors.cyan)],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/coin.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.game.totalCoins}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellowAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white,
                tabs: const [
                  Tab(text: 'Máy Bay'),
                  Tab(text: 'Kỹ Năng'),
                ],
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShipsTab(),
                    _buildSkillsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShipsTab() {
    // Placeholder for ship items
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildShopItem('player_red_off', 'Chiến Cơ Đỏ', 0, 'ship'),
            _buildShopItem('player_blue_off', 'Chiến Cơ Xanh', 0, 'ship'),
            _buildShopItem('chienco_hong', 'Chiến Cơ Hồng', 100, 'ship'),
            _buildShopItem('chienco_xanh', 'Chiến Cơ Xanh', 100, 'ship'),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsTab() {
    // Placeholder for skill items
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildShopItem('skill_samxet', 'Sấm Sét', 500, 'skill'),
            _buildShopItem('skill_hinhtron', 'Vòng Tròn Hủy Diệt', 800, 'skill'),
            _buildShopItem('skill_cauvong', 'Laser Cầu Vồng', 1200, 'skill'),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(String imageName, String itemName, int price, String type) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Image.asset('assets/images/$imageName.png', fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red, size: 40)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Giá: $price',
                    style: const TextStyle(fontSize: 16, color: Colors.yellowAccent),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.game.totalCoins >= price) {
                  widget.game.spendCoins(price);
                  // TODO: Add item to player's inventory
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Mua'),
            ),
          ],
        ),
      ),
    );
  }
}
