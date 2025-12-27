import 'package:flutter/material.dart';
import 'package:Phoenix_Blast/my_game.dart';
import 'package:Phoenix_Blast/services/firebase_service.dart';

class ShopOverlay extends StatefulWidget {
  final MyGame game;
  const ShopOverlay({super.key, required this.game});

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  Future<Map<String, dynamic>?>? _playerDataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayerData();
  }

  void _loadPlayerData() {
    setState(() {
      _playerDataFuture = _firebaseService.getPlayerData();
    });
  }

  void _handlePurchase(String itemId, String itemType, int price) async {
    final success = await _firebaseService.purchaseItem(itemId, itemType, price);
    if (success) {
      await widget.game.updatePlayerData();
      _loadPlayerData();
    }
  }

  void _handleEquip(String itemId, String itemType) async {
    final success = await _firebaseService.equipItem(itemId, itemType);
    if (success) {
      if (itemType == 'skin') {
        widget.game.currentSkin = itemId;
      } else if (itemType == 'skill') {
        widget.game.currentSkill = itemId;
      }
      _loadPlayerData();
    }
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
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _playerDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('Không thể tải dữ liệu người chơi.'));
              }

              final playerData = snapshot.data!;
              final totalCoins = (playerData['coins'] ?? 0) as int;

              return Column(
                children: [
                  _buildHeader(totalCoins),
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
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildShipsTab(playerData),
                        _buildSkillsTab(playerData),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int totalCoins) {
    return Padding(
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
                  '$totalCoins',
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
    );
  }

  Widget _buildShipsTab(Map<String, dynamic> playerData) {
    final skinsOwned = Map<String, bool>.from(playerData['skinsOwned'] ?? {});
    final currentSkin = playerData['currentSkin'] as String?;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildShopItem('vang', 'Phi Thuyền Vàng', 0, 'skin', skinsOwned, currentSkin, playerData['coins'] ?? 0),
            _buildShopItem('maybay', 'Phi Thuyền Tím', 100, 'skin', skinsOwned, currentSkin, playerData['coins'] ?? 0),
            _buildShopItem('player_red_off', 'Chiến Cơ Đỏ', 100, 'skin', skinsOwned, currentSkin, playerData['coins'] ?? 0),
            _buildShopItem('player_blue_off', 'Chiến Cơ Xanh Lam', 100, 'skin', skinsOwned, currentSkin, playerData['coins'] ?? 0),
            _buildShopItem('chienco_hong', 'Chiến Cơ Hồng', 150, 'skin', skinsOwned, currentSkin, playerData['coins'] ?? 0),
            _buildShopItem('chienco_xanh', 'Chiến Cơ Xanh Neon', 150, 'skin', skinsOwned, currentSkin, playerData['coins'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsTab(Map<String, dynamic> playerData) {
    final skillsOwned = Map<String, bool>.from(playerData['skillsOwned'] ?? {});
    final currentSkill = playerData['currentSkill'] as String?;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildShopItem('skill_samxet', 'Sấm Sét', 500, 'skill', skillsOwned, currentSkill, playerData['coins'] ?? 0, description: 'Tia sét hủy diệt kẻ thù trên đường thẳng.'),
            _buildShopItem('skill_hinhtron', 'Vòng Tròn Hủy Diệt', 800, 'skill', skillsOwned, currentSkill, playerData['coins'] ?? 0, description: 'Tạo một vụ nổ lớn xung quanh phi thuyền.'),
            _buildShopItem('skill_cauvong', 'Laser Cầu Vồng', 1200, 'skill', skillsOwned, currentSkill, playerData['coins'] ?? 0, description: 'Bắn ra những tia laser mạnh mẽ, đa sắc màu.'),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(String itemId, String itemName, int price, String itemType, Map<String, bool> ownedItems, String? currentItem, int userCoins, {String? description}) {
    final isOwned = ownedItems[itemId] ?? false;
    final isEquipped = isOwned && currentItem == itemId;

    Widget button;
    if (isEquipped) {
      button = ElevatedButton(
        onPressed: null, 
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        child: const Text('Đang sử dụng'),
      );
    } else if (isOwned) {
      button = ElevatedButton(
        onPressed: () => _handleEquip(itemId, itemType),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text('Sử dụng'),
      );
    } else {
      button = ElevatedButton(
        onPressed: userCoins >= price ? () => _handlePurchase(itemId, itemType, price) : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: const Text('Mua'),
      );
    }

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
              child: Image.asset('assets/images/$itemId.png', fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red, size: 40)),
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
                   if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    isOwned ? 'Đã sở hữu' : 'Giá: $price',
                    style: TextStyle(fontSize: 16, color: isOwned ? Colors.greenAccent : Colors.yellowAccent),
                  ),
                ],
              ),
            ),
            button,
          ],
        ),
      ),
    );
  }
}
