import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:briefed/main.dart';
import 'package:briefed/services/storage_service.dart';

void main() {
  testWidgets('Briefed app starts on splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();

    await tester.pumpWidget(
      const ProviderScope(
        child: BriefedApp(),
      ),
    );

    expect(find.text('Briefed.'), findsOneWidget);
  });
}
