
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng đã hủy đăng nhập
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Lỗi khi đăng nhập với Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<bool> hasNickname() async {
    if (currentUser == null) return false;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.exists && doc.data()!.containsKey('nickname');
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
    
    String? nickname = await getNickname();
    if (nickname == null) return;

    await _firestore.collection('scores').add({
      'userId': currentUser!.uid,
      'nickname': nickname,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getTopScores() {
    return _firestore
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(5)
        .snapshots();
  }
}
