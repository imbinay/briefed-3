// FIRESTORE RULES NEEDED:
// match /users/{uid}/gameResults/{doc} {
//   allow read, write: if request.auth.uid == uid;
// }
// Add this to your Firebase console rules.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
// ignore: unused_import
import '../features/xp/xp_service.dart';

class GameResult {
  final String gameId;
  final String gameName;
  final int score;
  final int total;
  final int xpEarned;
  final DateTime playedAt;

  const GameResult({
    required this.gameId,
    required this.gameName,
    required this.score,
    required this.total,
    required this.xpEarned,
    required this.playedAt,
  });

  Map<String, dynamic> toMap() => {
        'gameId': gameId,
        'gameName': gameName,
        'score': score,
        'total': total,
        'xpEarned': xpEarned,
        'playedAt': Timestamp.fromDate(playedAt),
        'percentage': total > 0 ? (score / total * 100).round() : 0,
      };
}

class GameResultsService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<void> saveResult(GameResult result) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      final uid = user.uid;
      final batch = _db.batch();

      final resultRef =
          _db.collection('users').doc(uid).collection('gameResults').doc();

      batch.set(resultRef, result.toMap());

      final userRef = _db.collection('users').doc(uid);
      batch.set(
          userRef,
          {
            'lastGameAt': FieldValue.serverTimestamp(),
            'totalGamesPlayed': FieldValue.increment(1),
            'totalGameXp': FieldValue.increment(result.xpEarned),
            'bestScores': {
              result.gameId: {
                'score': result.score,
                'total': result.total,
                'percentage': result.total > 0
                    ? (result.score / result.total * 100).round()
                    : 0,
              }
            },
            'gamesPlayed': {
              result.gameId: FieldValue.increment(1),
            },
            'gameXp': {
              result.gameId: FieldValue.increment(result.xpEarned),
            }
          },
          SetOptions(merge: true));

      final gameLeaderRef = _db
          .collection('leaderboards')
          .doc('games')
          .collection(result.gameId)
          .doc(uid);
      batch.set(
          gameLeaderRef,
          {
            'uid': uid,
            'displayName': user.displayName ?? user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'xp': FieldValue.increment(result.xpEarned),
            'gamesPlayed': FieldValue.increment(1),
            'lastScore': result.score,
            'lastTotal': result.total,
            'lastPercentage': result.total > 0
                ? (result.score / result.total * 100).round()
                : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      await batch.commit();
      print('[GameResults] Saved: ${result.gameName} '
          '${result.score}/${result.total}');
    } catch (e) {
      print('[GameResults] Save failed: $e');
    }
  }

  static Future<List<GameResult>> getRecentResults({
    int limit = 10,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    try {
      final snap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('gameResults')
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data();
        return GameResult(
          gameId: d['gameId'] as String? ?? '',
          gameName: d['gameName'] as String? ?? '',
          score: (d['score'] as num? ?? 0).toInt(),
          total: (d['total'] as num? ?? 0).toInt(),
          xpEarned: (d['xpEarned'] as num? ?? 0).toInt(),
          playedAt: (d['playedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('[GameResults] Fetch failed: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getGameSummary() async {
    final user = AuthService.currentUser;
    if (user == null) return {};

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }
}
