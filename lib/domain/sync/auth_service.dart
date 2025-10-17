import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final authUserProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

class AuthService {
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final gAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: gAuth.idToken,
      accessToken: gAuth.accessToken,
    );
    final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
    return userCred.user;
  }

  Future<User?> signInAnonymously() async {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user;
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
  String? uid() => FirebaseAuth.instance.currentUser?.uid;
}

