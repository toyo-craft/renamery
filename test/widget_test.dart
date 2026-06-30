import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:renamery/core/directory_provider.dart';
import 'package:renamery/main.dart';

void main() {
  testWidgets('ReNameryApp builds without the template counter assumptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => DirectoryProvider())],
        child: const ReNameryApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
