import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _playerRef(String uid) =>
      _firestore.collection('playerData').doc(uid);

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("Bắt đầu đăng nhập Google...");

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Người dùng đã hủy đăng nhập.");
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await ensurePlayerDoc(user);
      }

      debugPrint("Đăng nhập thành công: \${user?.displayName}");
      return user;
    } catch (e) {
      debugPrint("Lỗi khi đăng nhập với Google: \$e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    debugPrint("Đã đăng xuất.");
  }

  Future<void> ensurePlayerDoc(User user) async {
    final ref = _playerRef(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      debugPrint("Tạo tài liệu mới cho người dùng: \${user.uid}");
      await ref.set({
        'email': user.email,
        'nickname': user.displayName ?? '',
        'coins': 0,
        'bestScore': 0,
        'lastScore': 0,
        'skinsOwned': {'vang': true, 'maybay': true},
        'currentSkin': 'vang',
        'skillsOwned': {},
        'currentSkill': '',
        'redeemedCodes': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  Future<bool> hasNickname() async {
    final user = currentUser;
    if (user == null) return false;
    final doc = await _playerRef(user.uid).get();
    final data = doc.data();
    return doc.exists && data != null && (data['nickname'] as String?)?.isNotEmpty == true;
  }

  Future<void> setNickname(String nickname) async {
    final user = currentUser;
    if (user == null) return;
    await _playerRef(user.uid).set({
      'nickname': nickname,
    }, SetOptions(merge: true));
  }

  Future<String?> getNickname() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _playerRef(user.uid).get();
    return doc.data()?['nickname'] as String?;
  }

  Future<Map<String, dynamic>?> getPlayerData() async {
    if (currentUser == null) return null;
    final doc = await _playerRef(currentUser!.uid).get();
    return doc.data();
  }

  Future<void> onGameEnd({
    required int score,
    required int coinsEarned,
    int? newBestScore,
  }) async {
    if (currentUser == null) return;

    final playerDocRef = _playerRef(currentUser!.uid);

    try {
      final updates = <String, dynamic>{
        'coins': FieldValue.increment(coinsEarned),
        'lastScore': score,
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      
      if (newBestScore != null) {
        updates['bestScore'] = newBestScore;
      }
      
      await playerDocRef.update(updates);
    } catch (e) {
      debugPrint("Lỗi khi xử lý cuối game: \$e");
    }
  }

  Future<bool> purchaseItem(String itemId, String itemType, int price) async {
    if (currentUser == null) return false;
    final playerDocRef = _playerRef(currentUser!.uid);
    final itemField = itemType == 'skin' ? 'skinsOwned' : 'skillsOwned';

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(playerDocRef);

        if (!snapshot.exists || snapshot.data() == null) {
          throw Exception("Không tìm thấy dữ liệu người chơi.");
        }
        
        final data = snapshot.data()!;
        final currentCoins = (data['coins'] ?? 0) as int;

        if (currentCoins < price) {
          throw Exception('Không đủ xu!');
        }
        
        transaction.update(playerDocRef, {
          'coins': FieldValue.increment(-price),
          '${itemField}.${itemId}': true,
        });
      });
      return true;
    } catch (e) {
      debugPrint("Lỗi khi mua vật phẩm: \$e");
      return false;
    }
  }

  Future<bool> equipItem(String itemId, String itemType) async {
    if (currentUser == null) return false;
    final playerDocRef = _playerRef(currentUser!.uid);
    final currentItemField = itemType == 'skin' ? 'currentSkin' : 'currentSkill';

    try {
      await playerDocRef.update({currentItemField: itemId});
      return true;
    } catch (e) {
      debugPrint("Lỗi khi trang bị vật phẩm: \$e");
      return false;
    }
  }

  Future<String> redeemGiftCode(String code) async {
    if (currentUser == null) return "Bạn cần đăng nhập để thực hiện.";

    final codeRef = _firestore.collection('giftCodes').doc(code);
    final playerRef = _playerRef(currentUser!.uid);

    try {
      return await _firestore.runTransaction((transaction) async {
        final codeDoc = await transaction.get(codeRef);
        final playerDoc = await transaction.get(playerRef);

        if (!codeDoc.exists) {
          return "Mã không hợp lệ!";
        }

        final playerData = playerDoc.data()!;
        final List<dynamic> redeemedCodes = playerData['redeemedCodes'] ?? [];
        if (redeemedCodes.contains(code)) {
          return "Bạn đã sử dụng mã này rồi.";
        }

        final codeData = codeDoc.data()!;
        final int reward = codeData['reward'] as int;

        transaction.update(playerRef, {
          'coins': FieldValue.increment(reward),
          'redeemedCodes': FieldValue.arrayUnion([code])
        });

        return "Chúc mừng! Bạn nhận được $reward xu.";
      });
    } catch (e) {
      debugPrint("Lỗi khi đổi mã: $e");
      return "Đã có lỗi xảy ra. Vui lòng thử lại.";
    }
  }

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
