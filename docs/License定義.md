前提は、**ReNamery 全体を BSD 3-Clause License で配布**し、**現在の通信は更新確認のみ**、**将来は diagnostics / analytics / crash reporting を追加する可能性がある**、というものです。BSD 3-Clause は、再配布や改変を広く許容するライセンスなので、インストール同意や利用規約で **“no redistribution” “no modification” “no reverse engineering”** のような全面禁止をアプリ全体にかけない構成にするのが安全です。Apple は標準 EULA の代わりにカスタム EULA を平文で設定でき、Google Play はプライバシーポリシーをストア掲載面とアプリ内の両方に求め、個人データやセンシティブデータの扱いでは必要に応じてアプリ内の目立つ開示と同意を求めています。Microsoft Store でも、個人情報をアクセス・収集・送信する場合はプライバシーポリシー URL の提出が必要です。 ([Open Source Initiative](https://opensource.org/license/bsd-3-clause?utm_source=chatgpt.com "The 3-Clause BSD License"))

現時点での実務的なおすすめは、次の4点セットです。  
**1. LICENSE**: BSD 3-Clause License 原文  
**2. Installer Consent Notice**: インストーラや初回起動で見せる短い同意文  
**3. Terms of Use**: 詳細な利用規約  
**4. Privacy Policy**: 現状の実態に合わせたプライバシーポリシー  
特に Google Play 向けには、提出時点の **実際のデータ取扱い** を Data safety やプライバシーポリシーに一致させる必要があるため、将来の analytics をまだ未実装なら、「将来追加される場合がある。追加時には通知・改定・必要な同意取得を行う」と書く形が無難です。 ([Google ヘルプ](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en&utm_source=chatgpt.com "Provide information for Google Play's Data safety section"))

なお、以下の英語文面には、まだ確定していない箇所だけ角括弧で残しています。  
残りの差し替え候補は主に **[Contact Email] / [Website URL] / [Privacy Policy URL] / [Effective Date]** です。  
世界公開向けなので、Terms of Use には **non-waivable consumer rights clause** を入れています。これは、各国の強行法規に反しないようにするための実務上の調整です。

---

## 日本語まとめ

**採用方針**

- アプリ本体は **BSD 3-Clause License**
    
- 同意文は **BSD の権利を壊さない**
    
- 現在は **更新確認通信のみ**
    
- 将来の diagnostics / analytics / crash reporting は **追加時に開示・改定・必要な同意取得**
    
- 英語を主文として整備
    
- ストア外配布と各ストア配布で共通利用できるように設計
    

**そのまま使える構成**

- `LICENSE`
    
- `TERMS_OF_USE.txt`
    
- `PRIVACY_POLICY.txt`
    
- インストーラ用の短い同意文
    

**注意点**

- BSD 3-Clause 配布なのに、利用規約で再配布禁止・改変禁止を全面的に書くのは避ける
    
- Google Play ではプライバシーポリシーを **ストア listing とアプリ内の両方** に置く
    
- Apple は **Custom EULA を平文**で登録可能
    
- Microsoft Store は個人情報のアクセス・収集・送信があるなら **privacy policy URL** が必要  
    ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement/?utm_source=chatgpt.com "Provide a custom license agreement"))
    

---

## English text 1: LICENSE

```text
BSD 3-Clause License

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
```

この LICENSE は、BSD 3-Clause の標準的な条件と免責に沿う前提です。 ([Open Source Initiative](https://opensource.org/license/bsd-3-clause?utm_source=chatgpt.com "The 3-Clause BSD License"))

---

## English text 2: Installer Consent Notice

これは **MSI / MSIX / PKG / DMG / deb** のインストーラ画面や、ZIP / APK / tar 配布時の初回起動ダイアログ向けの短文です。Apple のカスタム EULA やストア外配布の共通たたき台としても使えます。 ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement/?utm_source=chatgpt.com "Provide a custom license agreement"))

```text
Installer Consent Notice

Application Name: ReNamery
Copyright Holder: Toyo Craft Lab

Please read the following before installing or using ReNamery.

By downloading, installing, launching, or using ReNamery, you acknowledge and agree that:

1. ReNamery is provided under the BSD 3-Clause License. Your use, redistribution, and modification rights are governed by that license and the accompanying copyright notice, license conditions, and disclaimer.

2. ReNamery is provided on an "AS IS" basis, without warranties of any kind, express or implied, including without limitation warranties of merchantability, fitness for a particular purpose, and non-infringement.

3. To the maximum extent permitted by applicable law, Toyo Craft Lab and its contributors shall not be liable for any direct, indirect, incidental, special, exemplary, or consequential damages arising out of or relating to the use of, or inability to use, ReNamery.

4. ReNamery may access the network for limited purposes such as checking for software updates, version information, release notes, or related service availability.

5. In future versions, Toyo Craft Lab may add optional features for diagnostics, crash reporting, analytics, or service quality improvement. If such features are introduced, Toyo Craft Lab will provide updated notices, policy updates, settings, and consent mechanisms where required by applicable law or platform policy.

6. Additional terms regarding use of the application are described in the Terms of Use and Privacy Policy made available with the application, on the distribution page, or within the application.

If you do not agree, do not install or use ReNamery.
```

---

## English text 3: Terms of Use

これは **詳細利用規約の本文** です。  
BSD 3-Clause の許容を壊さず、世界公開向けの最低限の実務条項を入れています。Google Play や Apple のストア条件とは別に、配布者としての条件整理に使う文面です。App Store ではカスタム EULA を平文で設定でき、Google Play ではアプリ内とストア listing の双方にプライバシーポリシーを用意する必要があります。 ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement/?utm_source=chatgpt.com "Provide a custom license agreement"))

```text
Terms of Use for ReNamery
Effective Date: [YYYY-MM-DD]

These Terms of Use ("Terms") govern your access to and use of ReNamery (the "Software"), provided by Toyo Craft Lab ("Toyo Craft Lab", "we", "us", or "our").

1. Scope

ReNamery is distributed under the BSD 3-Clause License. These Terms are intended to supplement, and not to restrict, the rights granted under the BSD 3-Clause License.

If any provision of these Terms is interpreted in a way that conflicts with rights granted to you under the BSD 3-Clause License, such provision shall be interpreted only to the extent necessary to avoid restricting those license rights.

2. License Basis

Your rights to use, copy, modify, and redistribute ReNamery are governed by the BSD 3-Clause License and any accompanying notices included with the Software.

You must retain the applicable copyright notice, license conditions, and disclaimer when redistributing the Software in source or binary form, as required by the BSD 3-Clause License.

You may not use the name "Toyo Craft Lab", "ReNamery", or the names of any contributors to endorse or promote derived products without prior written permission, except as permitted by applicable law or the BSD 3-Clause License.

3. Use of the Software

You are responsible for your own use of the Software.

You are solely responsible for any files, data, metadata, file names, content, folders, or other materials that you create, modify, rename, move, delete, import, export, or otherwise handle through ReNamery.

You agree not to use the Software in violation of any applicable law, regulation, third-party rights, or contractual obligation.

4. Updates and Changes

ReNamery may connect to the internet for limited purposes such as checking for software updates, version information, release notes, service availability, or related maintenance purposes.

We may modify, improve, suspend, replace, or discontinue any part of ReNamery at any time, with or without notice, subject to applicable law.

Future versions may include optional features related to diagnostics, crash reporting, analytics, telemetry, or service quality improvement. If such features are introduced, we will update the applicable notices and policies and obtain consent where required by applicable law or platform policy.

5. Privacy

Our collection, use, and disclosure of information, if any, are described in the Privacy Policy for ReNamery.

At the time of this version of these Terms, ReNamery is intended primarily to operate locally on the user's device, except for limited communications such as update checks or related service access.

If future versions introduce additional information processing, diagnostics, crash reporting, analytics, or similar functionality, the Privacy Policy and any required in-app notices or consent flows will be updated accordingly.

6. No Warranty

THE SOFTWARE IS PROVIDED "AS IS" AND "AS AVAILABLE", WITHOUT WARRANTY OF ANY KIND, TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW.

TOYO CRAFT LAB DISCLAIMS ALL WARRANTIES, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING, WITHOUT LIMITATION, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, NON-INFRINGEMENT, ACCURACY, QUIET ENJOYMENT, OR THAT THE SOFTWARE WILL BE ERROR-FREE, SECURE, OR UNINTERRUPTED.

7. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, TOYO CRAFT LAB AND ITS CONTRIBUTORS SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR FOR ANY LOSS OF DATA, LOSS OF FILES, LOSS OF PROFITS, LOSS OF BUSINESS, LOSS OF GOODWILL, BUSINESS INTERRUPTION, OR OTHER LOSSES ARISING OUT OF OR RELATING TO THE SOFTWARE OR YOUR USE OF OR INABILITY TO USE THE SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

THIS LIMITATION APPLIES REGARDLESS OF THE THEORY OF LIABILITY, WHETHER IN CONTRACT, TORT, STRICT LIABILITY, NEGLIGENCE, OR OTHERWISE.

8. File Handling and User Responsibility

ReNamery is a file management and renaming tool. You acknowledge that file operations may alter, move, replace, or delete file names, paths, or related data depending on your actions and settings.

You are responsible for verifying your own files and maintaining appropriate backups before performing file operations.

Toyo Craft Lab does not assume responsibility for user mistakes, misconfiguration, incompatible file environments, file loss, naming conflicts, or third-party application behavior affecting files handled through the Software.

9. Intellectual Property and Notices

Except for the rights expressly granted under the BSD 3-Clause License, all trademarks, service marks, logos, trade names, branding elements, and other identifiers associated with Toyo Craft Lab or ReNamery remain the property of their respective owners.

You may not remove or alter copyright notices, license notices, or attribution notices except as permitted by the BSD 3-Clause License or applicable law.

10. Third-Party Platforms and Distribution Channels

ReNamery may be distributed through third-party platforms, stores, package managers, websites, or direct downloads. Your use of such platforms may also be subject to the terms, policies, and technical requirements of those third parties.

Nothing in these Terms is intended to replace or override any mandatory platform terms that apply to your acquisition of the Software from a third-party app store or marketplace.

11. Changes to These Terms

We may revise these Terms from time to time.

If we make material changes, we may provide notice through the application, an update notice, a release note, the distribution page, the project website, or another reasonable method.

Your continued use of ReNamery after the effective date of revised Terms constitutes your acceptance of the revised Terms, except to the extent prohibited by applicable law or inconsistent with rights already granted under the BSD 3-Clause License.

12. International Use and Consumer Rights

ReNamery may be made available worldwide.

You are responsible for compliance with local laws that apply to your use of the Software.

Nothing in these Terms excludes, limits, or overrides any non-waivable consumer rights or protections that you may have under the laws applicable in your jurisdiction.

13. Governing Law and Jurisdiction

These Terms shall be governed by and construed in accordance with the laws of Japan, without regard to its conflict of laws principles.

Unless otherwise required by applicable law, the Tokyo District Court shall have exclusive jurisdiction as the court of first instance for disputes arising out of or relating to these Terms or the Software.

14. Contact

If you have questions about these Terms, please contact:

Toyo Craft Lab
Email: [Contact Email]
Website: [Website URL]
```

---

## English text 4: Privacy Policy

Google Play では、プライバシーポリシーは **アプリ内** と **Play Console の指定欄** の両方に必要です。将来、個人データやセンシティブデータの取得、あるいは危険権限やセンシティブ API に関わる機能を追加する場合は、ポリシー更新だけでなく、必要に応じて **separate in-app prominent disclosure and consent** が必要になります。Microsoft Store でも個人情報をアクセス・収集・送信するなら privacy policy URL が必要です。 ([Google ヘルプ](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en&utm_source=chatgpt.com "Prepare your app for review - Play Console Help"))

```text
Privacy Policy for ReNamery
Effective Date: [YYYY-MM-DD]

Toyo Craft Lab ("Toyo Craft Lab", "we", "us", or "our") provides ReNamery (the "App" or the "Software").

This Privacy Policy explains how ReNamery currently handles information and how we will communicate changes if future versions introduce additional data-related features.

1. Current Functionality

At the time of this version of the Privacy Policy, ReNamery is designed primarily to operate locally on the user's device as a file management and renaming application.

Currently, ReNamery may access the network for limited purposes such as:
- checking whether software updates are available,
- retrieving version information,
- retrieving release notes or update-related information, and
- accessing related service availability information.

2. Files and Local Content

ReNamery is intended to process files, folders, file names, and related data primarily on the user's device.

Unless explicitly stated in a specific feature, ReNamery is not intended to automatically upload the user's files or file contents to Toyo Craft Lab solely for ordinary file management use.

3. Future Diagnostics, Crash Reporting, and Analytics

Future versions of ReNamery may introduce optional or additional features such as:
- crash reporting,
- diagnostics,
- analytics,
- usage statistics,
- telemetry, or
- service quality and performance improvement features.

If such features are introduced, Toyo Craft Lab will update this Privacy Policy and, where required by applicable law or platform policy, provide additional notice, settings, opt-in choices, or consent requests within the application or through the applicable distribution channel.

4. Legal Basis and User Choice

Where required by applicable law, we will rely on an appropriate legal basis for processing information, such as your consent, our legitimate interests, contractual necessity, or compliance with legal obligations.

Where consent is required, you may refuse or withdraw consent in accordance with applicable law and the controls made available in the App or on the relevant platform.

5. Data Sharing

At the time of this version, any data exchange is intended to be limited to the update-related communications described above.

If future versions involve sharing information with service providers, analytics providers, crash-reporting providers, hosting providers, or other third parties, this Privacy Policy will be updated to describe the categories of recipients and the purpose of such sharing.

6. Data Retention

To the extent that future versions process personal data or diagnostic information, we will retain such information only for as long as reasonably necessary for the purposes described in the applicable notice or policy, unless a longer retention period is required by law.

7. International Availability

ReNamery may be made available worldwide.

If information is processed in connection with future online features, such information may be processed in countries other than your own, subject to applicable safeguards and legal requirements.

8. Children's Privacy

ReNamery is not specifically directed to children unless explicitly stated otherwise.

If we learn that personal information has been collected from a child in a manner requiring parental authorization under applicable law, we will take appropriate steps consistent with applicable law.

9. Security

We take reasonable steps appropriate to the nature of the information involved to protect information processed in connection with ReNamery.

However, no method of transmission or storage is completely secure, and we cannot guarantee absolute security.

10. Changes to This Privacy Policy

We may update this Privacy Policy from time to time.

If we make material changes, we may provide notice through the App, the distribution page, release notes, our website, or another reasonable method.

11. Contact

If you have any questions about this Privacy Policy, please contact:

Toyo Craft Lab
Email: [Contact Email]
Website: [Website URL]
Privacy Policy URL: [Privacy Policy URL]
```

---

## 使い分けの最終提案

**Windows MSI / MSIX / macOS PKG / Linux deb**

- Installer Consent Notice を表示
    
- `LICENSE`, `TERMS_OF_USE`, `PRIVACY_POLICY` を同梱
    

**ZIP / tar.gz / Android APK 直接配布**

- 配布ページに Installer Consent Notice 相当の短文
    
- 初回起動時に同意ダイアログ
    
- 同梱ファイルとして `LICENSE`, `TERMS_OF_USE`, `PRIVACY_POLICY`
    

**App Store**

- Apple 標準 EULA を使うか、上記 Terms をベースに Custom EULA 化
    
- カスタム EULA は平文で設定可能 ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement/?utm_source=chatgpt.com "Provide a custom license agreement"))
    

**Google Play**

- Privacy Policy URL を listing に設定
    
- アプリ内にも Privacy Policy を表示またはリンク
    
- 将来、個人データやセンシティブデータの追加取得があるなら、必要に応じて別個の in-app disclosure / consent を追加 ([Google ヘルプ](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en&utm_source=chatgpt.com "Prepare your app for review - Play Console Help"))
    

**Microsoft Store**

- 個人情報をアクセス・収集・送信する場合は privacy policy URL を提出 ([Microsoft Learn](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies?utm_source=chatgpt.com "Microsoft Store Policies version 7.19 - Windows apps"))
    
