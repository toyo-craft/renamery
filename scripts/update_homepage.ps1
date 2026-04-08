$filePath = "C:\Users\s.kodatai\OneDrive - 株式会社セラフ\source\toyo-craft\apps.html"
$bakPath = "$filePath.bak"

# 1. Backup
if (Test-Path $filePath) {
    Copy-Item $filePath $bakPath -Force
}

# 2. Read
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# 3. New Content
$newSection = @"
            <div class="app-card reveal" id="renamery">
                <div class="app-icon">
                    <img src="images/app_renamery.png" alt="ReNamery アイコン">
                </div>
                <div class="app-content">
                    <span class="app-status status-beta">ベータ版</span>
                    <h3>ReNamery <span class="u-font-sm u-text-light" style="margin-left:0.5em;">v0.12.0</span></h3>
                    <p>Windows
                        XP時代に開発が止まってしまった伝説的な高機能リネーマー「Namery」。その類まれな直感性と優れたUXを現代に復刻し、OSの垣根を超えて世界中の人々へ届けるための進化プロトタイプです。
                    </p>
                    
                    <div class="u-mt-2 u-mb-2 l-flex-gap-1">
                        <a href="https://github.com/toyo-craft/renamery/releases" target="_blank" class="btn btn-primary"
                            style="padding: 0.5rem 1.5rem;">最新版をダウンロード</a>
                        
                        <a href="https://renamery.toyo-craft.net/" target="_blank" class="btn btn-outline"
                            style="padding: 0.5rem 1.5rem;">WEB版デモ</a>
                    </div>
                    <p class="u-text-light u-font-sm">※対応OS: Windows 10/11, Android, Linux (.deb)</p>

                    <div class="u-mt-2 u-mb-2 u-font-md">
                        <a href="https://github.com/toyo-craft/renamery/issues" target="_blank" class="u-bold u-color-primary"
                            style="text-decoration: underline;">バグ報告・機能要望 (GitHub Issues)</a>
                        <span class="u-ml-2">/</span>
                        <a href="https://github.com/toyo-craft/renamery" target="_blank" class="u-ml-2 u-text-light"
                            style="text-decoration: underline;">ソースコードを表示</a>
                    </div>

                    <div class="app-screenshots pswp-gallery u-mt-2">
                        <a href="images/cap_renamery01.png" data-pswp-width="1549" data-pswp-height="862"
                            target="_blank">
                            <img src="images/cap_renamery01.png" alt="ReNamery スクリーンショット 1">
                        </a>
                        <a href="images/cap_renamery02.png" data-pswp-width="390" data-pswp-height="895"
                            target="_blank">
                            <img src="images/cap_renamery02.png" alt="ReNamery スクリーンショット 2">
                        </a>
                        <a href="images/cap_renamery03.png" data-pswp-width="1080" data-pswp-height="2400"
                            target="_blank">
                            <img src="images/cap_renamery03.png" alt="ReNamery スクリーンショット 3">
                        </a>
                        <a href="images/cap_renamery04.png" data-pswp-width="1080" data-pswp-height="2400"
                            target="_blank">
                            <img src="images/cap_renamery04.png" alt="ReNamery スクリーンショット 4">
                        </a>
                    </div>
                    <p class="app-note">
                        ※当アプリは、Jun Arai様の<a href="https://www.vector.co.jp/soft/winnt/util/se217399.html"
                            target="_blank"
                            class="app-link-external">'Namery'</a>をリスペクトして作成しました。但し作者御本人様との連絡手段が無くご確認ができておりません。もし問題等ございましたら、GitHubのIssueまたは<a
                            href="contact.html" class="app-link-external">問い合わせフォーム</a>からご意見くださると幸いです。
                    </p>
                </div>
            </div>
"@

# 4. Regex Replace
# Find from <div...id="renamery"> until <div...id="worldlines">
$pattern = '(?s)<div class="app-card reveal" id="renamery">.*?<div class="app-card reveal" id="worldlines">'
$replacement = $newSection + "`n`n            <div class=`"app-card reveal`" id=`"worldlines`">"
$updatedContent = $content -replace $pattern, $replacement

# 5. Write
[System.IO.File]::WriteAllText($filePath, $updatedContent, [System.Text.Encoding]::UTF8)
Write-Host "Update completed successfully."
