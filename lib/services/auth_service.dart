import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<User?> get userStream => _auth.authStateChanges();

  // 🔹 Guardar/atualizar utilizador no Firestore
  static Future<void> _saveUserToFirestore(User user) async {
    final ref = _db.collection("users").doc(user.uid);
    await ref.set({
      "uid": user.uid,
      "email": user.email,
      "name": user.displayName ?? "",
      "photoUrl": user.photoURL ?? "",
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge = atualiza sem apagar dados antigos
  }

  // 🔹 Login com Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      if (userCred.user != null) {
        await _saveUserToFirestore(userCred.user!);
      }
      return userCred;
    } catch (e) {
      print("⚠️ Erro no login Google: $e");
      return null;
    }
  }

  // 🔹 Criar conta com email/password
  static Future<UserCredential?> registerWithEmail(
      String email, String password) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCred.user != null) {
        await _saveUserToFirestore(userCred.user!);
      }
      return userCred;
    } catch (e) {
      print("⚠️ Erro no registo por email: $e");
      return null;
    }
  }

  // 🔹 Login com email/password
  static Future<UserCredential?> signInWithEmail(
      String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCred.user != null) {
        await _saveUserToFirestore(userCred.user!);
      }
      return userCred;
    } catch (e) {
      print("⚠️ Erro no login por email: $e");
      return null;
    }
  }

  // 🔹 Logout
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
