import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:renamery/core/directory_provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:renamery/ui/widgets/license_agreement_dialog.dart';

void main() {
  group('LicenseAgreementDialog localization', () {
    testWidgets('shows localized messages for supported locales',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const cases = [
        _LocaleCase(
          Locale('ja'),
          'ソフトウェア利用規約',
          '本ソフトウェアを利用するには、以下のライセンス条項に同意する必要があります。',
          '同意しない（アプリを終了する）',
          '同意して利用を開始する',
        ),
        _LocaleCase(
          Locale('ja', 'NM'),
          '利用規約',
          '利用するには、以下のライセンス条項への同意が必要です。',
          '同意しない（終了）',
          '同意して開始',
        ),
        _LocaleCase(
          Locale('en'),
          'Software License Agreement',
          'To use this software, you must agree to the following license terms.',
          'Decline and exit the app',
          'Agree and start using',
        ),
        _LocaleCase(
          Locale('zh'),
          '软件许可协议',
          '要使用本软件，您必须同意以下许可条款。',
          '不同意（退出应用）',
          '同意并开始使用',
        ),
        _LocaleCase(
          Locale('es'),
          'Acuerdo de licencia de software',
          'Para usar este software, debe aceptar los siguientes términos de licencia.',
          'No aceptar y salir de la app',
          'Aceptar y empezar a usar',
        ),
      ];

      for (final localeCase in cases) {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => DirectoryProvider(),
            child: MaterialApp(
              locale: localeCase.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: LicenseAgreementDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(localeCase.title), findsOneWidget);
        expect(find.text(localeCase.message), findsOneWidget);
        expect(find.text(localeCase.decline), findsOneWidget);
        expect(find.text(localeCase.accept), findsOneWidget);
      }
    });
  });
}

class _LocaleCase {
  const _LocaleCase(
    this.locale,
    this.title,
    this.message,
    this.decline,
    this.accept,
  );

  final Locale locale;
  final String title;
  final String message;
  final String decline;
  final String accept;
}
