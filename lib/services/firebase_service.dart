import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

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
        'nickname': '',
        'coins': 0,
        'bestScore': 0,
        'lastScore': 0,
        'skinsOwned': {'vang': true, 'maybay': true},
        'currentSkin': 'vang',
        'skillsOwned': {},
        'currentSkill': '',
        'wins': 0,
        'losses': 0,
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

  Stream<QuerySnapshot<Map<String, dynamic>>> top5Players() {
    return _firestore
        .collection('playerData')
        .orderBy('bestScore', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<void> onGameEnd({
    required bool isWin,
    required int score,
    required int coinsEarned,
  }) async {
    if (currentUser == null) return;

    final playerDocRef = _playerRef(currentUser!.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(playerDocRef);
        final data = snapshot.data();

        var updates = <String, dynamic>{
          'coins': FieldValue.increment(coinsEarned),
          'lastScore': score,
        };

        if (isWin) {
          updates['wins'] = FieldValue.increment(1);
        } else {
          updates['losses'] = FieldValue.increment(1);
        }

        final bestScore = data?['bestScore'] ?? 0;
        if (score > bestScore) {
          updates['bestScore'] = score;
        }
        
        transaction.update(playerDocRef, updates);
      });
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
          '$itemField.$itemId': true,
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
}
