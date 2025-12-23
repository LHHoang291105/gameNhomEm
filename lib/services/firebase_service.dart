import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("Bắt đầu đăng nhập Google...");
      
      // Đảm bảo đã đăng xuất trước đó để hiển thị hộp thoại chọn tài khoản
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Người dùng đã hủy đăng nhập.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint("Đăng nhập thành công: ${userCredential.user?.displayName}");
      return userCredential.user;
    } catch (e) {
      debugPrint("Lỗi khi đăng nhập với Google: $e");
      // Nếu lỗi là 12500 hoặc 10, thường là do thiếu SHA-1 hoặc sai cấu hình Firebase console
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Lỗi khi đăng xuất: $e");
    }
  }

  Future<bool> hasNickname() async {
    if (currentUser == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.exists && doc.data()!.containsKey('nickname');
    } catch (e) {
      debugPrint("Lỗi kiểm tra nickname: $e");
      return false;
    }
  }

  Future<void> setNickname(String nickname) async {
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser!.uid).set({
      'nickname': nickname,
      'email': currentUser!.email,
    }, SetOptions(merge: true));
  }

  Future<String?> getNickname() async {
    if (currentUser == null) return null;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['nickname'];
  }

  Future<void> saveScore(int score) async {
    if (currentUser == null) return;
    
    try {
      String? nickname = await getNickname();
      if (nickname == null) return;

      await _firestore.collection('scores').add({
        'userId': currentUser!.uid,
        'nickname': nickname,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Lỗi lưu điểm: $e");
    }
  }

  Stream<QuerySnapshot> getTopScores() {
    return _firestore
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(5)
        .snapshots();
  }
}
