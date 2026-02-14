import 'package:flutter/material.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    const version = '0.1.0'; // TODO: Get from package_info_plus if needed

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Logo / App Name
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_note,
                    size: 40, color: colorScheme.onPrimaryContainer),
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
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
    if (!await launchUrl(uri)) {
      // Flutter 3.x url_launcher might need generic handling or mode
      // For Windows, it usually works.
      debugPrint('Could not launch $url');
    }
  }
}
