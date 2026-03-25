結論からいうと、**VS Codeの「GitHubサインイン」を都度切り替える運用より、Git側で“対象ワークディレクトリだけ別アカウント”に分ける**のが一番安定します。VS Code には GitHub 認証が組み込まれていますが、実際の push / pull の認証は Git の SSH / HTTPS 設定に依存します。なお、**Copilot については公式に workspace / profile 単位で別 GitHub アカウントを使う設定があります**が、これは一般の Git リモート認証とは別です。 ([Visual Studio Code][1])

おすすめは次の順です。

**1. いちばんおすすめ: SSH鍵をアカウントごとに分ける**
GitHub 公式も、複数アカウントを使う場合は **別SSH鍵** を使う方法を案内しています。`~/.ssh/config` でホスト別に鍵を分け、該当リポジトリの `origin` をそのホスト名に向ける形です。`IdentitiesOnly yes` を付けると、複数鍵が ssh-agent に載っていても狙った鍵を使いやすくなります。 ([GitHub Docs][2])

例です。

```sshconfig
# ~/.ssh/config
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

対象リポジトリだけ work 側に向けます。

```bash
git remote set-url origin git@github-work:ORG/REPO.git
```

個人用はこうです。

```bash
git remote set-url origin git@github-personal:USER/REPO.git
```

**2. 対象ワークディレクトリ配下だけ user.name / user.email を自動切替する**
Git には `includeIf` があり、**特定パス配下のリポジトリだけ別設定ファイルを読み込む**ことができます。これは「`C:/work/clients/` 配下だけ会社アカウント」といった運用にかなり向いています。Git の `user.name` / `user.email` はリポジトリ単位でも設定できます。 ([Git][3])

```ini
; ~/.gitconfig
[user]
    name = Personal Name
    email = personal@example.com

[includeIf "gitdir:C:/Users/you/work/"]
    path = ~/.gitconfig-work
```

```ini
; ~/.gitconfig-work
[user]
    name = Work Name
    email = work@example.com
```

この構成にして、さらにその配下のリポジトリの `origin` を `git@github-work:...` にしておけば、**コミット者情報も認証鍵も両方分離**できます。 ([GitHub Docs][2])

**3. 1リポジトリだけ別アカウントなら、ローカル設定だけでも十分**
本当に1つの作業ディレクトリだけなら、そのリポジトリでだけ次を実行すれば足ります。これはグローバル設定ではなく、そのリポジトリだけに効きます。 ([GitHub Docs][4])

```bash
git config user.name "Work Name"
git config user.email "work@example.com"
git remote set-url origin git@github-work:ORG/REPO.git
```

**4. HTTPS運用もできるが、SSHより少し煩雑**
GitHub 公式は、HTTPS でもアカウントごとに別 PAT を使い、**リポジトリごとに別資格情報**を保存する方法を案内しています。Git Credential Manager 側でも、URL の `name@host` 部分を使って同一ドメイン上の複数IDを区別する考え方があります。なので HTTPS でも可能ですが、日常運用では SSH のほうが分かりやすいです。 ([GitHub Docs][2])

**拡張機能はあるか？**
あります。たとえば **gitUserSwitcher** は workspace 内で Git user を切り替える拡張で、username / email / SSH key の切替をうたっています。**GitShift** も複数 GitHub アカウントの切替や workspace-specific 設定をうたっています。 ([Visual Studio Marketplace][5])

ただし、ここは注意点があります。
**これらは便利ツールではありますが、公式の標準運用というより補助です。** 認証事故を避けたいなら、**拡張機能で切り替えるのではなく、Git の設定で固定する**ほうが安全です。VS Code公式で workspace / profile 単位の別アカウント設定が明示されているのは、少なくとも Copilot 側です。 ([Visual Studio Code][6])

私のおすすめを一言でまとめると、次です。

* **Gitの認証**: SSH鍵を personal / work で分ける
* **Gitの作者情報**: `includeIf` でワークディレクトリ単位に切り替える
* **VS Code拡張**: あくまで見やすさ・補助用途

Windows + VS Code 前提で、あなたの環境向けに **そのまま貼れる `.ssh/config` と `.gitconfig` の完成形** まで作れます。

[1]: https://code.visualstudio.com/docs/sourcecontrol/github "Working with GitHub in VS Code"
[2]: https://docs.github.com/en/account-and-profile/how-tos/account-management/managing-multiple-accounts "Managing multiple accounts - GitHub Docs"
[3]: https://git-scm.com/docs/git-config "Git - git-config Documentation"
[4]: https://docs.github.com/en/get-started/git-basics/setting-your-username-in-git?utm_source=chatgpt.com "Setting your username in Git"
[5]: https://marketplace.visualstudio.com/items?itemName=mikeeeyy04.gitshift "
        GitShift - Visual Studio Marketplace
    "
[6]: https://code.visualstudio.com/docs/copilot/setup "Set up GitHub Copilot in VS Code"
