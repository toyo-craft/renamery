import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  /// CHANGELOG.md から直近 [count] 件のリリースエントリをパースする
  static Future<List<_ReleaseEntry>> _parseChangelog({int count = 3}) async {
    try {
      final raw = await rootBundle.loadString('CHANGELOG.md');
      final entries = <_ReleaseEntry>[];
      final versionPattern = RegExp(r'^## \[(.+?)\]\s*-\s*(.+)$');

      String? currentVersion;
      String? currentDate;
      final buffer = StringBuffer();

      for (final line in raw.split('\n')) {
        final match = versionPattern.firstMatch(line.trim());
        if (match != null) {
          // 前のエントリを保存
          if (currentVersion != null) {
            entries.add(_ReleaseEntry(
              version: currentVersion,
              date: currentDate ?? '',
              body: buffer.toString().trim(),
            ));
            if (entries.length >= count) break;
            buffer.clear();
          }
          currentVersion = match.group(1);
          currentDate = match.group(2);
        } else if (currentVersion != null) {
          // # Changelog などのヘッダー行はスキップ
          if (!line.trim().startsWith('# ')) {
            buffer.writeln(line);
          }
        }
      }
      // 最後のエントリ
      if (currentVersion != null && entries.length < count) {
        entries.add(_ReleaseEntry(
          version: currentVersion,
          date: currentDate ?? '',
          body: buffer.toString().trim(),
        ));
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Object>>(
      future: Future.wait([
        PackageInfo.fromPlatform(),
        _parseChangelog(),
      ]),
      builder: (context, snapshot) {
        final version = (snapshot.data?[0] as PackageInfo?)?.version ?? '...';
        final releases = (snapshot.data?[1] as List<_ReleaseEntry>?) ?? [];

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Logo / App Name
                  Image.asset(
                    'assets/icon/app_icon.png',
                    width: 64,
                    height: 64,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.edit_note,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ReNamery',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                  Text(
                    '${l10n.labelAboutVersion} $version',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),

                  // 2. Credits (Respect)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.labelAboutRespect,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _launchUrl(
                              'https://www.vector.co.jp/soft/winnt/util/se217399.html'),
                          child: Text(
                            'https://www.vector.co.jp/soft/winnt/util/se217399.html',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        // Removed Original Idea as requested
                        _buildCreditRow(
                            context, l10n.labelAboutDev, "Toyo Craft Lab"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Website Link (with Launch)
                  OutlinedButton.icon(
                    onPressed: () => _launchUrl('https://toyo-craft.net/'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l10n.labelAboutVisitWebsite),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.labelAboutCopyright,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  // 4. リリースノート（直近3件）
                  if (releases.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '更新履歴',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...releases
                        .map((entry) => _buildReleaseEntry(context, entry)),
                  ],

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReleaseEntry(BuildContext context, _ReleaseEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    // bodyの各行をパースして、カテゴリと項目に分ける
    final lines = entry.body.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('### ')) {
        // カテゴリヘッダー（例: ### 新機能）
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            trimmed.substring(4),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ));
      } else if (trimmed.startsWith('- ')) {
        // 項目
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ',
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurfaceVariant)),
              Expanded(
                child: Text(
                  trimmed.substring(2),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${entry.version}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.date,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
          if (widgets.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...widgets,
          ],
        ],
      ),
    );
  }

  Widget _buildCreditRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label : ',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary),
        ),
        Text(value),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}

class _ReleaseEntry {
  final String version;
  final String date;
  final String body;

  const _ReleaseEntry({
    required this.version,
    required this.date,
    required this.body,
  });
}
