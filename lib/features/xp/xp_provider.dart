import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'xp_service.dart';

class XpState {
  final int totalXp;
  final int level;
  final String levelTitle;
  final double levelProgress;
  final int xpForNextLevel;

  const XpState({
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.levelProgress,
    required this.xpForNextLevel,
  });
}

class XpNotifier extends StateNotifier<XpState> {
  XpNotifier() : super(_fromService());

  static XpState _fromService() => XpState(
        totalXp: XpService.getTotalXp(),
        level: XpService.getLevel(),
        levelTitle: XpService.getLevelTitle(),
        levelProgress: XpService.getLevelProgress(),
        xpForNextLevel: XpService.getXpForNextLevel(),
      );

  Future<void> addXp(int amount) async {
    await XpService.addXp(amount);
    state = _fromService();
  }

  void reload() {
    state = _fromService();
  }
}

final xpProvider = StateNotifierProvider<XpNotifier, XpState>(
  (ref) => XpNotifier(),
);
