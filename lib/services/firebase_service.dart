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

  // 1) Đăng nhập + khởi tạo doc user (1 lần)
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("Bắt đầu đăng nhập Google...");

      await _googleSignIn.signOut(); // để chọn tài khoản
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await ensurePlayerDoc(user); // 🔥 QUAN TRỌNG
      }

      debugPrint("Đăng nhập thành công: ${user?.displayName}");
      return user;
    } catch (e) {
      debugPrint("Lỗi khi đăng nhập với Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 2) Tạo doc user nếu chưa có + set mặc định shop (skin/skill)
  Future<void> ensurePlayerDoc(User user) async {
    final ref = _playerRef(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'nickname': user.displayName ?? 'Player',

        'coins': 0,
        'bestScore': 0,
        'lastScore': 0,

        // ✅ mặc định shop
        'skinsOwned': {'vang': true, 'maybay': true},
        'currentSkin': 'vang',
        'skillsOwned': {'laser': true},
        'currentSkill': 'laser',

        'wins': 0,
        'losses': 0,

        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  // 3) Nickname nằm trong playerData
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
      'email': user.email,
    }, SetOptions(merge: true));
  }

  Future<String?> getNickname() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _playerRef(user.uid).get();
    return doc.data()?['nickname'] as String?;
  }

  // 4) Coins: cộng/trừ bằng increment (thắng/thua đều gọi được)
  Future<void> addCoins(int delta) async {
    final user = currentUser;
    if (user == null) return;
    await _playerRef(user.uid).set({
      'coins': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> getCoins() async {
    final user = currentUser;
    if (user == null) return 0;
    final doc = await _playerRef(user.uid).get();
    return (doc.data()?['coins'] ?? 0) as int;
  }

  // 5) Kết thúc game: coin luôn lưu, bestScore chỉ khi thắng (và cao hơn)
  // Hàm này sẽ thay thế cho việc gọi saveScore và updateCoins riêng lẻ
  Future<void> onGameEnd({
    required bool isWin,
    required int score,
    required int coinsEarned,
  }) async {
    if (currentUser == null) return;

    final playerDocRef = _firestore.collection('playerData').doc(currentUser!.uid);

    try {
      // Tự động cộng số xu kiếm được vào tổng xu trên server
      await playerDocRef.update({'coins': FieldValue.increment(coinsEarned)});

      // Chỉ lưu điểm vào bảng xếp hạng nếu thắng
      if (isWin) {
        await _firestore.collection('scores').add({
          'score': score,
          'nickname': await getNickname() ?? 'Player',
          'userId': currentUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Lỗi khi kết thúc game: $e");
    }
  }

// Hàm này dùng để tiêu xu, sử dụng Transaction để đảm bảo an toàn
  Future<bool> spendCoinsOnline(int amount) async {
    if (currentUser == null) return false;

    final playerDocRef = _firestore.collection('playerData').doc(currentUser!.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(playerDocRef);
        final currentCoins = snapshot.get('coins') as int;

        if (currentCoins < amount) {
          // Ném lỗi nếu không đủ xu
          throw Exception('Không đủ xu!');
        }

        transaction.update(playerDocRef, {'coins': currentCoins - amount});
      });
      return true; // Giao dịch thành công
    } catch (e) {
      print("Lỗi khi tiêu xu: $e");
      return false; // Giao dịch thất bại
    }
  }
}
