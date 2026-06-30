import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renamery/core/directory_provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class LicenseAgreementDialog extends StatelessWidget {
  const LicenseAgreementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // BSD 3-Clause License Text
    const licenseText = '''
Copyright (c) 2026, Toyo Craft Lab
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';

    return PopScope(
      canPop: false, // ダイアログを閉じられないようにする
      child: AlertDialog(
        title: Text(l10n.labelLicenseAgreementTitle),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.labelLicenseAgreementMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    licenseText,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              if (Platform.isAndroid || Platform.isIOS) {
                SystemNavigator.pop();
              } else {
                exit(0);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.labelLicenseDeclineExit),
          ),
          TextButton(
            onPressed: () {
              context.read<DirectoryProvider>().acceptLicense();
              Navigator.of(context).pop();
            },
            child: Text(l10n.labelLicenseAcceptStart),
          ),
        ],
      ),
    );
  }
}
