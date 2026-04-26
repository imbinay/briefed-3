import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static bool get isSignedIn => _auth.currentUser != null;
  static bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  static String get accountLabel {
    final user = _auth.currentUser;
    if (user == null) return 'Not signed in';
    if (user.isAnonymous) return 'Guest account';
    return user.email ?? user.displayName ?? 'Signed in';
  }

  static Future<void> initGoogleSignIn() {
    return GoogleSignIn.instance.initialize();
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _ensureUserDocument(credential.user);
    return credential;
  }

  static Future<UserCredential> createAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      await credential.user?.updateDisplayName(cleanName);
    }
    await _ensureUserDocument(credential.user, name: cleanName);
    return credential;
  }

  static Future<UserCredential> continueAsGuest() async {
    final credential = await _auth.signInAnonymously();
    await _ensureUserDocument(credential.user, isGuest: true);
    return credential;
  }

  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(userCredential.user);
    return userCredential;
  }

  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  static Future<void> syncQuizResult({
    required UserData userData,
    required QuizResult result,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'knowledgeScore': userData.knowledgeScore,
      'streak': userData.streak,
      'longestStreak': userData.longestStreak,
      'totalQuizzes': userData.totalQuizzes,
      'lastPlayedDate': userData.lastPlayedDate,
      'selectedCategories': userData.selectedCategories,
      'notificationHour': userData.notificationHour,
      'notificationMinute': userData.notificationMinute,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef
        .collection('quiz_results')
        .doc(result.date)
        .set(result.toJson(), SetOptions(merge: true));
  }

  static Future<void> _ensureUserDocument(
    User? user, {
    String? name,
    bool isGuest = false,
  }) async {
    if (user == null) return;

    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();

    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': name?.isNotEmpty == true ? name : user.displayName,
      'photoUrl': user.photoURL,
      'isGuest': user.isAnonymous || isGuest,
      'updatedAt': now,
    };

    if (snap.exists) {
      await ref.set(data, SetOptions(merge: true));
    } else {
      await ref.set({
        ...data,
        'knowledgeScore': 0,
        'streak': 0,
        'totalQuizzes': 0,
        'createdAt': now,
      });
    }
  }
}
