// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get labelMainTab => '基本';

  @override
  String get labelSubTab => '拡張';

  @override
  String get labelExtraTab => '高度';

  @override
  String get labelEtcTab => '属性';

  @override
  String get labelCategoryAdd => 'テキストの追加';

  @override
  String get labelCategoryRemove => 'テキストの削除';

  @override
  String get labelCategoryReplace => '置換と変換';

  @override
  String get labelCategoryNumbering => '連番 (ナンバリング)';

  @override
  String get labelCategoryExtension => '拡張子';

  @override
  String get labelCategoryAdvanced => '高度な操作';

  @override
  String get labelStringInput => '文字列';

  @override
  String get labelColName => '現在のファイル名';

  @override
  String get labelColNewName => '新しいファイル名';

  @override
  String get labelColSize => 'サイズ';

  @override
  String get labelColPath => 'パス';

  @override
  String get labelColType => '種別';

  @override
  String get labelColDate => '更新日時';

  @override
  String get labelColAttr => '属性';

  @override
  String get labelOpPrefix => '先頭に追加';

  @override
  String get labelOpSuffix => '末尾に追加';

  @override
  String get labelOpInsert => '指定位置に挿入';

  @override
  String get labelOpDeleteStart => '先頭から削除';

  @override
  String get labelOpDeleteEnd => '末尾から削除';

  @override
  String get labelOpDeleteFrom => '指定位置から削除';

  @override
  String get labelOpCapitalize => '先頭を大文字化';

  @override
  String get labelOpUpper => 'すべて大文字化';

  @override
  String get labelOpLower => 'すべて小文字化';

  @override
  String get labelOpExtChange => '拡張子を変更';

  @override
  String get labelOpExtAdd => '拡張子を追加';

  @override
  String get labelOpExtRemove => '拡張子を削除';

  @override
  String get labelOpExtUpper => '拡張子を大文字化';

  @override
  String get labelOpExtLower => '拡張子を小文字化';

  @override
  String get labelSubExtChangeTitle => '拡張子変更';

  @override
  String get labelSubFormatTitle => '英単語整形';

  @override
  String get labelSubFormatProperCase => '単語の先頭を大文字化 (Space/Hyphen/Underscore)';

  @override
  String get labelSubListTitle => '文字列リネーム';

  @override
  String get labelSubListModeText => 'テキスト入力 (Original[TAB]New)';

  @override
  String get labelSubListSample1 => 'サンプル: 連番ファイル';

  @override
  String get labelSubListSample2 => 'サンプル: 拡張子一括置換';

  @override
  String get labelSubListSample3 => 'サンプル: 特定文字の置換';

  @override
  String get labelSubListHint =>
      'old_name.txt\tnew_name.txt\nfile01.png\timage01.png';

  @override
  String get labelExtraAppendDate => 'ファイルの日付を付加';

  @override
  String get labelExtraDateFormatHint => '日付フォーマット (例: yyyymmdd_)';

  @override
  String get labelExtraPosition => '位置';

  @override
  String get labelExtraFront => '前方';

  @override
  String get labelExtraBack => '後方';

  @override
  String get labelExtraConvHalfToFull => '半角を全角にする';

  @override
  String get labelExtraConvFullToHalf => '全角を半角にする';

  @override
  String get labelExtraConvKataToHira => '全角カナをひらがなにする';

  @override
  String get labelExtraConvHiraToKata => 'ひらがなを全角カナにする';

  @override
  String get labelExtraConvFullAlphaToHalf => '全角英字を半角にする';

  @override
  String get labelExtraConvNumToHalf => '数字を半角にする';

  @override
  String get labelEtcAttribReadOnly => '読み取り専用';

  @override
  String get labelEtcAttribHidden => '隠しファイル';

  @override
  String get labelEtcAttribArchive => 'アーカイブ';

  @override
  String get labelEtcAttribSystem => 'システムファイル';

  @override
  String get labelEtcTimestampChange => 'タイムスタンプを変更する';

  @override
  String get labelEtcPickTime => '時刻を選択してください';

  @override
  String get labelEtcPickDateTooltip => '日付と時刻を選択';

  @override
  String get labelEtcTimestampNote => '(Ex 2002/03/30 17:30 のように指定します。)';

  @override
  String get labelEtcAttributeChange => '属性を変更する';

  @override
  String get labelEtcCautionTitle => '取り消し操作不能';

  @override
  String get labelEtcCautionMessage =>
      'このカテゴリ（タイムスタンプ・属性）の変更は、アンドゥ機能で元に戻すことができません。慎重に操作してください。';

  @override
  String get labelUndo => '戻す';

  @override
  String get labelExecute => '実行';

  @override
  String get labelErrorInvalidFilename => 'エラー：ファイル名に禁止文字が含まれています';

  @override
  String get labelCopyName => 'コピー (現在名)';

  @override
  String get labelCopyPath => 'コピー (パス)';

  @override
  String get labelCopyFullPath => '現在のフルパスリストをコピー';

  @override
  String get labelCopyOptions => '現在のリストをコピー';

  @override
  String get labelCopyUndo => 'リネーム後のファイル名リストをコピー';

  @override
  String get labelCopyListClipboard => '現在のファイル名リストをコピー';

  @override
  String get labelMoveUp => '上に移動';

  @override
  String get labelMoveDown => '下に移動';

  @override
  String get labelRefresh => '全て更新';

  @override
  String get labelMenuMore => 'その他の操作';

  @override
  String get labelMenuSettings => 'アプリ設定';

  @override
  String get labelMenuFolder => 'メニュー (フォルダ)';

  @override
  String get labelNumStringNumber => '文字列 + 連番';

  @override
  String get labelNumOriginalNumber => '現在名 + 連番';

  @override
  String get labelNumNumberString => '連番 + 文字列';

  @override
  String get labelNumNumberOriginal => '連番 + 現在名';

  @override
  String get labelNumBaseStringNumber => '基本名 + 文字列 + 連番';

  @override
  String get labelNumBaseStringOriginal => '基本名 + 文字列 + 現在名';

  @override
  String get labelNumRelativeStringNumber => '相対名 + 文字列 + 連番';

  @override
  String get labelNumRelativeStringOriginal => '相対名 + 文字列 + 現在名';

  @override
  String get labelNumNumberStringBase => '連番 + 文字列 + 基本名';

  @override
  String get labelNumNumberStringRelative => '連番 + 文字列 + 相対名';

  @override
  String get labelReplaceFrom => 'を';

  @override
  String get labelReplaceTo => 'に置換';

  @override
  String get labelFullPath => '現在の場所 > ';

  @override
  String get labelSelectAll => 'すべて選択';

  @override
  String get labelDeselectAll => '選択解除';

  @override
  String get labelSettingsFilterTitle => '表示設定 (フィルタ)';

  @override
  String get labelFilterAll => '全てのファイル';

  @override
  String get labelFilterSpecific => '指定';

  @override
  String get labelFilterHideSystem => 'システムファイルを非表示';

  @override
  String get labelFilterRecursive => '下位フォルダ検索';

  @override
  String get labelBetaListRenameHint => '※ ベータ版が有効なため表示されています';

  @override
  String get labelCtxUpOneFolder => '一つ上のフォルダへ';

  @override
  String get labelCtxRenameGeneral => '名前の変更 (一般)';

  @override
  String get labelCtxBatchRename => '一括変更 (Namery)';

  @override
  String get labelCtxOpenWithAssoc => '関連付けで開く';

  @override
  String get labelCtxMoveToTop => '選択項目を先頭に移動';

  @override
  String get labelCtxMoveToBottom => '選択項目を最後尾に移動';

  @override
  String get labelCtxDeleteItems => '選択項目を削除 (Del)';

  @override
  String get labelCtxMoveCaret => 'キャレット移動';

  @override
  String get labelCtxCaretSettings => 'キャレットの設定';

  @override
  String get labelCtxRefresh => '最新の情報に更新 (F5)';

  @override
  String get labelCtxProperties => 'プロパティ(R)';

  @override
  String get labelFilterPreview => 'プレビュー表示';

  @override
  String get labelExtensionLower => '拡張子は小文字化';

  @override
  String get labelNavBack => '戻る';

  @override
  String get labelNavForward => '進む';

  @override
  String get labelNavUp => '一つ上のフォルダへ';

  @override
  String get labelNavHistory => '履歴';

  @override
  String get labelNoHistory => '履歴がありません';

  @override
  String get labelScanStop => 'スキャン停止';

  @override
  String get labelHistoryBack => '履歴 (戻る)';

  @override
  String get labelHistoryForward => '履歴 (進む)';

  @override
  String get labelNavQuickAccess => 'クイックアクセス';

  @override
  String get labelDeleteFront => '前から';

  @override
  String get labelDeleteBack => '後から';

  @override
  String get labelDeleteUntil => 'まで削除';

  @override
  String get labelFindHint => '検索 (Find)';

  @override
  String get labelReplaceHint => '置換 (Replace)';

  @override
  String get labelRegex => '正規表現';

  @override
  String get labelString => '文字列';

  @override
  String get labelStartDigit => '開始/桁';

  @override
  String get labelStart => '開始';

  @override
  String get labelDigit => '桁';

  @override
  String get labelSettingsTitle => '設定';

  @override
  String get labelSettingsSectionDisplay => '表示設定';

  @override
  String get labelSettingsSectionAppearance => '外観';

  @override
  String get labelSettingsSectionOS => '動作モード (OS設定)';

  @override
  String get labelSettingsSectionInitialDir => '初期フォルダ';

  @override
  String get labelSettingsSectionReset => 'リセット';

  @override
  String get labelSettingsTouchModeTitle => 'タッチモード (ゆったり表示)';

  @override
  String get labelSettingsTouchModeSubtitle => 'リストやボタンの間隔を広げます';

  @override
  String get labelSettingsMenuLabelTitle => 'メニュー表記 (言語)';

  @override
  String get labelSettingsLangJP => '日本語';

  @override
  String get labelSettingsLangNamery => 'Namery';

  @override
  String get labelSettingsLangEN => '英語';

  @override
  String get labelSettingsLangCN => '中国語';

  @override
  String get labelSettingsLangES => 'スペイン語';

  @override
  String get labelSettingsThemeTitle => 'テーマモード';

  @override
  String get labelSettingsThemeSystem => 'システム';

  @override
  String get labelSettingsThemeLight => 'ライト';

  @override
  String get labelSettingsThemeDark => 'ダーク';

  @override
  String get labelSettingsThemeGray => 'グレー';

  @override
  String get labelSettingsColorTitle => 'テーマカラー';

  @override
  String get labelSettingsOSTitle => 'OSモード';

  @override
  String get labelSettingsOSSubtitle => 'ファイル名の文字制限などをOSに合わせます';

  @override
  String get labelSettingsOSAuto => '自動';

  @override
  String get labelSettingsInitDirTitle => '起動時の場所';

  @override
  String get labelSettingsInitDirLast => '前回終了時の場所';

  @override
  String get labelSettingsInitDirFixed => '指定した場所';

  @override
  String get labelSettingsClearHistory => '入力履歴を削除';

  @override
  String get labelSettingsClearHistorySub => '文字列補完などの入力履歴を削除します';

  @override
  String get labelSettingsResetAll => '全設定をリセット';

  @override
  String get labelSettingsResetAllSub => '初期状態に戻します';

  @override
  String get labelSettingsBetaTitle => 'Beta版機能を有効にする';

  @override
  String get labelSettingsBetaSubtitle => 'テスト中の新機能を表示します（例：リストリネーム）';

  @override
  String get labelDialogCancel => 'キャンセル';

  @override
  String get labelDialogDelete => '削除';

  @override
  String get labelDialogReset => 'リセット';

  @override
  String get labelMsgHistoryCleared => '履歴を削除しました';

  @override
  String get labelMsgSettingsReset => '設定をリセットしました';

  @override
  String get labelFilterHideFolders => 'フォルダーを隠す';

  @override
  String get labelFilterShowFolders => 'フォルダーを表示';

  @override
  String get labelPreviewNoSelection => '選択されていません';

  @override
  String labelPreviewSelectedCount(int count) {
    return '$count 個のファイルが選択されています';
  }

  @override
  String get labelPreviewImageLoadFailed => '画像の読み込みに失敗しました';

  @override
  String get labelPreviewUnavailable => 'プレビューを利用できません';

  @override
  String labelPreviewOmitted(String size) {
    return '... (省略されました: 全 $size KB)';
  }

  @override
  String get labelPreviewBinaryError => 'プレビューを利用できません: バイナリまたは不明なエンコーディング';

  @override
  String get labelGoRenamery => 'リネームを実行';

  @override
  String get labelTermFolder => 'フォルダー';

  @override
  String get labelTermFile => 'ファイル';

  @override
  String get labelTypeImage => '画像';

  @override
  String get labelTypePDF => 'PDF';

  @override
  String get labelTypeVideo => '動画';

  @override
  String get labelTypeAudio => '音楽';

  @override
  String get labelTypeDocument => '文書';

  @override
  String get labelTypeExecutable => 'アプリ';

  @override
  String get labelTypeArchive => '圧縮';

  @override
  String get labelTypeOther => 'その他';

  @override
  String get labelSettingsOSMac => 'Mac (Finder互換)';

  @override
  String get labelSettingsOSLinux => 'Linux';

  @override
  String get labelSettingsOSiOS => 'iOS (iPhone/iPad)';

  @override
  String get labelSettingsOSAndroid => 'Android';

  @override
  String labelMsgExecutedCount(int count) {
    return '$count 個のファイルをリネームしました';
  }

  @override
  String get labelMsgNoSelection => 'ファイルが選択されていません';

  @override
  String get labelCopyListPath => '現在の相対パスリストをコピー';

  @override
  String get labelMenuGo => '移動';

  @override
  String get labelNoFiles => 'ファイルがありません';

  @override
  String labelSelectFolderPrompt(Object term) {
    return '$termを選択してください';
  }

  @override
  String get labelNavTitle => 'ナビゲーション';

  @override
  String get labelNavPC => 'PC';

  @override
  String get labelNumSaveSequenceTooltip => '変更後の連番数字を保存（次回リネーム時に連番を継続）';

  @override
  String labelStatusDisplayCount(int current, int total, int selected) {
    return '現在の表示: $current / 全 $total ファイル : 選択 $selected ファイル';
  }

  @override
  String labelStatusTotalCount(int total, int selected) {
    return '全 $total ファイル : 選択 $selected ファイル';
  }

  @override
  String get labelStatusProcessing => '処理中...';

  @override
  String get labelStatusReady => '準備完了';

  @override
  String get labelDeleteConfirmTitle => '削除の確認';

  @override
  String labelDeleteConfirmMessage(int count) {
    return '$count 個のファイルを完全に削除しますか？\nこの操作は元に戻せません。';
  }

  @override
  String labelMsgDeletedCount(int count) {
    return '$count 個のファイルを削除しました';
  }

  @override
  String get labelUndoTitle => '処理の復元';

  @override
  String labelUndoConfirm(int count) {
    return '直前に行った $count 件の変更を元に戻しますか？';
  }

  @override
  String get labelMsgUndoSuccess => '復元しました';

  @override
  String get labelUndoRecoverBtn => '復元';

  @override
  String get labelMsgNoUndoRecord => '直前の変更記録がありません';

  @override
  String get labelMsgUndoRecordCopied => '直前の変更記録をクリップボードにコピーしました';

  @override
  String labelMsgCopyNamesSuccess(int count) {
    return '$count 件のファイル名をコピーしました';
  }

  @override
  String labelMsgCopyFilesSuccess(int count) {
    return '$count 件のファイルをコピーしました';
  }

  @override
  String labelMsgCutFilesSuccess(int count) {
    return '$count 件のファイルを切り取りました';
  }

  @override
  String labelMsgCopyRelativePathsSuccess(int count) {
    return '$count 件のファイルパス(相対)をコピーしました';
  }

  @override
  String labelMsgCopyFullPathsSuccess(int count) {
    return '$count 件のフルパスをコピーしました';
  }

  @override
  String get labelSettingsAboutTitle => 'アプリについて';

  @override
  String get labelAboutVersion => 'バージョン';

  @override
  String get labelAboutOriginal => '原案・オリジナル';

  @override
  String get labelAboutDev => '企画・開発';

  @override
  String get labelAboutCopyright => '© 2024 Toyo Craft Lab.';

  @override
  String get labelAboutRespect =>
      '当アプリは、Jun Arai 様の \'Namery\' をリスペクトして作成されました。';

  @override
  String get labelAboutVisitWebsite => 'ウェブサイトを表示';

  @override
  String get labelHistoryTooltip => '履歴を表示';

  @override
  String get labelSettingsFolders => 'フォルダ表示';

  @override
  String get labelSettingsShowSystemFiles => 'システムファイルを表示';

  @override
  String get labelSettingsSystemFiles => 'システムファイル';

  @override
  String get labelSettingsDisableRecursive => '下位フォルダ検索を無効';

  @override
  String get labelSettingsRecursive => '下位フォルダ';

  @override
  String get labelDialogTrashTitle => '項目の削除';

  @override
  String get labelDialogTrashMessage => '選択したファイルをゴミ箱に移動しますか？';

  @override
  String get labelCtxPasteItems => '項目を貼り付け';

  @override
  String get labelCtxCopyItems => 'コピー';

  @override
  String get labelCtxCutItems => '切り取り';

  @override
  String get labelCtxCreateFolder => '新しいフォルダーの作成';

  @override
  String get labelFilterOptions => '検索と表示設定';

  @override
  String get labelMenuRenameSettings => 'リネーム設定';

  @override
  String get labelDialogClose => '閉じる';

  @override
  String get labelSearchHint => 'ファイル名で検索...';

  @override
  String get labelRegexSearchHint => '正規表現で検索...';

  @override
  String get labelPermissionFileAccessTitle => 'ファイルアクセス権限の設定';

  @override
  String get labelPermissionFileAccessMessage =>
      '本アプリでファイルをリネームするには、Androidシステムの設定で「すべてのファイルの管理」を許可する必要があります。\n\n次の画面で「ReNamery」を探して、スイッチをONにしてください。';

  @override
  String get labelPermissionFileAccessButton => '設定画面へ進む';

  @override
  String get labelLicenseAgreementTitle => 'ソフトウェア利用規約';

  @override
  String get labelLicenseAgreementMessage =>
      '本ソフトウェアを利用するには、以下のライセンス条項に同意する必要があります。';

  @override
  String get labelLicenseDeclineExit => '同意しない（アプリを終了する）';

  @override
  String get labelLicenseAcceptStart => '同意して利用を開始する';

  @override
  String get labelAppTitle => 'ReNamery - ファイル名を安全に一括変更 | 東洋クラフト';

  @override
  String labelUpdateAvailable(String version) {
    return '新しいバージョン (v$version) が利用可能です';
  }

  @override
  String get labelViewSettings => '設定を見る';

  @override
  String get labelLanguagePromptMessage => '表示言語はアプリ設定で変更できます。';

  @override
  String get labelLanguagePromptAction => '言語設定';

  @override
  String labelRecommendedLanguagePageMessage(String language, String url) {
    return 'ブラウザーの言語に合う$languageページがあります: $url';
  }

  @override
  String get labelRecommendedLanguagePageAction => '開く';

  @override
  String get labelAppExitTitle => 'アプリの終了';

  @override
  String get labelAppExitConfirm => 'ReNamery を終了しますか？';

  @override
  String get labelExit => '終了する';

  @override
  String get labelSkipInvalidTitle => 'エラーを含むファイルのスキップ確認';

  @override
  String labelSkipInvalidMessage(int invalidCount, int validCount) {
    return '選択されたファイルの中に、ファイル名が不正（禁止文字・重複など）なものが $invalidCount 件あります。\n\nこれらを除外し、正常な $validCount 件のファイルのみリネームを実行しますか？';
  }

  @override
  String get labelSkipAndContinue => 'スキップして続行';

  @override
  String labelMsgExecutedWithSkipped(int executedCount, int invalidCount) {
    return '$executedCount 件成功、$invalidCount 件はエラーのためスキップされました';
  }

  @override
  String get labelMsgNoExecutableFiles => '実行できるファイルがありませんでした';

  @override
  String get labelWebSelectFolderPromptTitle => 'ローカルフォルダを選択して開始';

  @override
  String get labelWebSelectFolderPromptMessage =>
      'Chrome系ブラウザで、選択したフォルダ内のファイル名をまとめて変更できます。';

  @override
  String get labelWebSelectFolderPromptPrivacy => 'データはデバイス以外に持ち出されることはありません。';

  @override
  String get labelWebSelectFolderPromptDesktopBeforeLink => 'シームレスな操作には、';

  @override
  String get labelDesktopAppVersionLink => 'デスクトップ・アプリ版';

  @override
  String get labelWebSelectFolderPromptDesktopAfterLink => 'をお勧めします。';

  @override
  String get labelWebUnsupportedPromptTitle => 'このブラウザでは利用できません';

  @override
  String get labelWebUnsupportedPromptMessage =>
      'ChromeまたはEdgeなどの対応ブラウザでお試しください。';

  @override
  String get labelSelectFolder => 'フォルダを選択';

  @override
  String get labelLicenseCannotExitTitle => 'アプリを終了できません';

  @override
  String get labelLicenseCannotExitMessage =>
      'ブラウザではアプリ側からタブを閉じられません。利用しない場合は、このタブを閉じてください。';

  @override
  String get labelDropOneFolder => 'フォルダを1つだけドロップしてください。';

  @override
  String get labelDropFolderNotFile => 'ファイルではなくフォルダを1つだけドロップしてください。';

  @override
  String get labelDropUnsupported => 'この環境ではフォルダのドラッグ&ドロップに対応していません。';

  @override
  String get labelDropOpenFailed => 'フォルダを開けませんでした。';

  @override
  String get labelDropHereToOpen => 'ここにフォルダをドロップして開く';

  @override
  String get labelFileNotFound => 'ファイルが存在しません';

  @override
  String get labelWindowsPropertiesFailed => 'Windowsプロパティ画面を開けませんでした';

  @override
  String labelPropertiesTitle(String name) {
    return 'プロパティ: $name';
  }

  @override
  String get labelPropertyKind => '種類';

  @override
  String get labelPropertyFileFolder => 'ファイル フォルダ';

  @override
  String get labelPropertyFile => 'ファイル';

  @override
  String get labelPropertyLocation => '場所';

  @override
  String get labelPropertySize => 'サイズ';

  @override
  String get labelPropertyModified => '更新日時';

  @override
  String get labelPropertyAttributes => '属性';

  @override
  String get labelWebUnsupportedBrowserMessage =>
      'このブラウザでは、ローカルフォルダ連携に必要な機能が利用できません。ChromeまたはEdgeなど、対応しているPC向けブラウザでお試しください。';

  @override
  String get labelWebLocalFolderPickerTitle => 'ローカルフォルダを選択';

  @override
  String get labelWebLocalFolderPickerSubtitle =>
      'Chrome / Edge などの対応ブラウザで利用できます';

  @override
  String get labelWebNoSavedDirectories => '選択済みフォルダはまだありません。';

  @override
  String get labelWebDirectoryPermissionDenied => 'フォルダへのアクセスが許可されませんでした。';

  @override
  String get labelWebAccessUnavailable =>
      'フォルダまたはファイルを読み込めませんでした。移動、削除、同期中などにより一部の項目へアクセスできない可能性があります。';

  @override
  String get labelWebNameRequired => 'ファイル名を入力してください。';

  @override
  String get labelWebInvalidFileNameChars =>
      'ファイル名に使用できない文字が含まれています: / \\ : * ? \" < > |';

  @override
  String get labelWebDuplicateItem => '同じ名前の項目が既にあります。';

  @override
  String get labelWebDuplicateFile => '同じ名前のファイルが既にあります。';

  @override
  String get labelWebItemAccessLost => '項目へのアクセス情報が失われています。フォルダを選択し直してください。';

  @override
  String get labelWebFileAccessLost => 'ファイルへのアクセス情報が失われています。フォルダを選択し直してください。';

  @override
  String get labelForgetQuickAccessTitle => 'クイックアクセスから解除しますか？';

  @override
  String labelForgetQuickAccessMessage(String name) {
    return '「$name」をReNameryのクイックアクセスから解除します。\n\nフォルダやファイル自体は削除されません。\n再度利用する場合は「ローカルフォルダを選択」から追加してください。';
  }

  @override
  String get labelForget => '解除';

  @override
  String get labelForgetQuickAccessAction => 'クイックアクセスから解除';

  @override
  String get labelForgetQuickAccessSuccess =>
      'クイックアクセスから解除しました。ファイルは削除されていません。';

  @override
  String get labelForgetQuickAccessFailure => 'クイックアクセスから解除できませんでした。';

  @override
  String get labelArchiveContents => 'アーカイブ内容:';

  @override
  String labelPreviewError(String message) {
    return 'エラー: $message';
  }

  @override
  String labelPreviewUnsupportedWeb(String target) {
    return 'Web版では$targetの内容プレビューは未対応です。\nファイル名、種類、サイズなどの情報は一覧で確認できます。';
  }

  @override
  String get labelPreviewTargetThisFile => 'このファイル';

  @override
  String labelPreviewTargetExtensionFile(String extension) {
    return '$extensionファイル';
  }

  @override
  String get labelScanConfirmTitle => 'スキャンの確認';

  @override
  String labelScanConfirmCount(int count) {
    return '$count 件のファイルが見つかりました。\nスキャンを続行しますか？';
  }

  @override
  String labelScanConfirmTime(int count) {
    return 'スキャン開始から5秒が経過しました（現在 $count 件）。\nこのまま続行しますか？';
  }

  @override
  String get labelScanConfirmStall => '応答が一時的に途絶えています。スキャンを続行しますか？';

  @override
  String get labelScanCancelClear => '中止 (クリア)';

  @override
  String get labelScanStopAndShow => 'ここで止めて表示';

  @override
  String get labelScanContinue => '続行する';
}

/// The translations for Japanese (`ja_NM`).
class AppLocalizationsJaNm extends AppLocalizationsJa {
  AppLocalizationsJaNm() : super('ja_NM');

  @override
  String get labelMainTab => '基本';

  @override
  String get labelSubTab => '拡張';

  @override
  String get labelExtraTab => '高度';

  @override
  String get labelEtcTab => '属性';

  @override
  String get labelCategoryAdd => '追加';

  @override
  String get labelCategoryRemove => '削除';

  @override
  String get labelCategoryReplace => '置換/変換';

  @override
  String get labelCategoryNumbering => '連番';

  @override
  String get labelCategoryExtension => '拡張子';

  @override
  String get labelCategoryAdvanced => '高度';

  @override
  String get labelStringInput => '文字列';

  @override
  String get labelColName => '現在の名前';

  @override
  String get labelColNewName => '新しい名前';

  @override
  String get labelColSize => 'サイズ';

  @override
  String get labelColPath => 'パス';

  @override
  String get labelColType => '種別';

  @override
  String get labelColDate => '更新日時';

  @override
  String get labelColAttr => '属性';

  @override
  String get labelOpPrefix => '先頭に追加';

  @override
  String get labelOpSuffix => '末尾に追加';

  @override
  String get labelOpInsert => '位置指定挿入';

  @override
  String get labelOpDeleteStart => '先頭から削除';

  @override
  String get labelOpDeleteEnd => '末尾から削除';

  @override
  String get labelOpDeleteFrom => '位置指定削除';

  @override
  String get labelOpCapitalize => '先頭大文字';

  @override
  String get labelOpUpper => '大文字化';

  @override
  String get labelOpLower => '小文字化';

  @override
  String get labelOpExtChange => '拡張子変更';

  @override
  String get labelOpExtAdd => '拡張子追加';

  @override
  String get labelOpExtRemove => '拡張子削除';

  @override
  String get labelOpExtUpper => '拡張子大文字';

  @override
  String get labelOpExtLower => '拡張子小文字';

  @override
  String get labelSubExtChangeTitle => '拡張子の変更';

  @override
  String get labelSubFormatTitle => '整形';

  @override
  String get labelSubFormatProperCase => '単語先頭大文字 (Space/Hyphen/_)';

  @override
  String get labelSubListTitle => 'リストリネーム';

  @override
  String get labelSubListModeText => 'リスト入力 (元[TAB]新)';

  @override
  String get labelSubListSample1 => '例: 連番ファイル';

  @override
  String get labelSubListSample2 => '例: 拡張子置換';

  @override
  String get labelSubListSample3 => '例: 文字置換';

  @override
  String get labelSubListHint => 'old.txt\tnew.txt\na.png\tb.png';

  @override
  String get labelExtraAppendDate => '日付を付加';

  @override
  String get labelExtraDateFormatHint => '書式 (yyyymmdd_)';

  @override
  String get labelExtraPosition => '位置';

  @override
  String get labelExtraFront => '前方';

  @override
  String get labelExtraBack => '後方';

  @override
  String get labelExtraConvHalfToFull => '半角→全角';

  @override
  String get labelExtraConvFullToHalf => '全角→半角';

  @override
  String get labelExtraConvKataToHira => 'カナ→かな';

  @override
  String get labelExtraConvHiraToKata => 'かな→カナ';

  @override
  String get labelExtraConvFullAlphaToHalf => '全角英字→半角';

  @override
  String get labelExtraConvNumToHalf => '数字→半角';

  @override
  String get labelEtcAttribReadOnly => '読専';

  @override
  String get labelEtcAttribHidden => '隠し';

  @override
  String get labelEtcAttribArchive => 'アーカイブ';

  @override
  String get labelEtcAttribSystem => 'システム';

  @override
  String get labelEtcTimestampChange => '日時の変更';

  @override
  String get labelEtcPickTime => '時刻を選択';

  @override
  String get labelEtcPickDateTooltip => '日時を選択';

  @override
  String get labelEtcTimestampNote => '(2002/03/30 17:30 形式)';

  @override
  String get labelEtcAttributeChange => '属性の変更';

  @override
  String get labelEtcCautionTitle => '警告';

  @override
  String get labelEtcCautionMessage => '属性・日時の変更は元に戻せません。';

  @override
  String get labelUndo => '戻す';

  @override
  String get labelExecute => '実行';

  @override
  String get labelErrorInvalidFilename => 'エラー: 禁止文字が含まれています';

  @override
  String get labelCopyName => '名前コピー';

  @override
  String get labelCopyPath => 'パスコピー';

  @override
  String get labelCopyFullPath => '現在のフルパスリストをコピー';

  @override
  String get labelCopyOptions => '現在のリストをコピー';

  @override
  String get labelCopyUndo => 'リネーム後の名前リストをコピー';

  @override
  String get labelCopyListClipboard => '現在のファイル名リストをコピー';

  @override
  String get labelMoveUp => '上へ';

  @override
  String get labelMoveDown => '下へ';

  @override
  String get labelRefresh => '更新';

  @override
  String get labelMenuMore => 'メニュー';

  @override
  String get labelMenuSettings => '設定';

  @override
  String get labelMenuFolder => 'フォルダ';

  @override
  String get labelNumStringNumber => '文字列 + 連番';

  @override
  String get labelNumOriginalNumber => '現在名 + 連番';

  @override
  String get labelNumNumberString => '連番 + 文字列';

  @override
  String get labelNumNumberOriginal => '連番 + 現在名';

  @override
  String get labelNumBaseStringNumber => '基本名 + 文字列 + 連番';

  @override
  String get labelNumBaseStringOriginal => '基本名 + 文字列 + 現在名';

  @override
  String get labelNumRelativeStringNumber => '相対名 + 文字列 + 連番';

  @override
  String get labelNumRelativeStringOriginal => '相対名 + 文字列 + 現在名';

  @override
  String get labelNumNumberStringBase => '連番 + 文字列 + 基本名';

  @override
  String get labelNumNumberStringRelative => '連番 + 文字列 + 相対名';

  @override
  String get labelReplaceFrom => 'を';

  @override
  String get labelReplaceTo => 'に置換';

  @override
  String get labelFullPath => '場所 > ';

  @override
  String get labelSelectAll => '全選択';

  @override
  String get labelDeselectAll => '解除';

  @override
  String get labelSettingsFilterTitle => 'フィルタ';

  @override
  String get labelFilterAll => '全ファイル';

  @override
  String get labelFilterSpecific => '指定...';

  @override
  String get labelFilterHideSystem => 'システムを隠す';

  @override
  String get labelFilterRecursive => '下位フォルダ';

  @override
  String get labelBetaListRenameHint => '※ Beta機能';

  @override
  String get labelCtxUpOneFolder => '上へ';

  @override
  String get labelCtxRenameGeneral => '名前の変更';

  @override
  String get labelCtxBatchRename => '一括変更 (NM)';

  @override
  String get labelCtxOpenWithAssoc => '関連付けで開く';

  @override
  String get labelCtxMoveToTop => '先頭へ移動';

  @override
  String get labelCtxMoveToBottom => '最後尾へ移動';

  @override
  String get labelCtxDeleteItems => '削除 (Del)';

  @override
  String get labelCtxMoveCaret => 'キャレット移動';

  @override
  String get labelCtxCaretSettings => 'キャレット設定';

  @override
  String get labelCtxRefresh => '更新 (F5)';

  @override
  String get labelCtxProperties => 'プロパティ';

  @override
  String get labelFilterPreview => 'プレビュー';

  @override
  String get labelExtensionLower => '拡張子小文字';

  @override
  String get labelNavBack => '戻る';

  @override
  String get labelNavForward => '進む';

  @override
  String get labelNavUp => '上へ';

  @override
  String get labelNavHistory => '履歴';

  @override
  String get labelNoHistory => '履歴なし';

  @override
  String get labelScanStop => 'スキャン停止';

  @override
  String get labelHistoryBack => '履歴戻る';

  @override
  String get labelHistoryForward => '履歴進む';

  @override
  String get labelNavQuickAccess => 'クイックアクセス';

  @override
  String get labelDeleteFront => '前方削除';

  @override
  String get labelDeleteBack => '後方削除';

  @override
  String get labelDeleteUntil => 'まで削除';

  @override
  String get labelFindHint => '検索文字列';

  @override
  String get labelReplaceHint => '置換文字列';

  @override
  String get labelRegex => '正規表現';

  @override
  String get labelString => '文字列';

  @override
  String get labelStartDigit => '開始/桁';

  @override
  String get labelStart => '開始';

  @override
  String get labelDigit => '桁';

  @override
  String get labelSettingsTitle => '設定';

  @override
  String get labelSettingsSectionDisplay => '表示';

  @override
  String get labelSettingsSectionAppearance => '外観';

  @override
  String get labelSettingsSectionOS => 'OSモード';

  @override
  String get labelSettingsSectionInitialDir => '初期フォルダ';

  @override
  String get labelSettingsSectionReset => 'リセット';

  @override
  String get labelSettingsTouchModeTitle => 'タッチモード';

  @override
  String get labelSettingsTouchModeSubtitle => '間隔を広げます';

  @override
  String get labelSettingsMenuLabelTitle => '表記 (言語)';

  @override
  String get labelSettingsLangJP => '日本語';

  @override
  String get labelSettingsLangNamery => 'Namery';

  @override
  String get labelSettingsLangEN => 'English';

  @override
  String get labelSettingsLangCN => '中国語';

  @override
  String get labelSettingsLangES => 'スペイン語';

  @override
  String get labelSettingsThemeTitle => 'テーマ';

  @override
  String get labelSettingsThemeSystem => 'システム';

  @override
  String get labelSettingsThemeLight => 'ライト';

  @override
  String get labelSettingsThemeDark => 'ダーク';

  @override
  String get labelSettingsThemeGray => 'グレー';

  @override
  String get labelSettingsColorTitle => 'カラー';

  @override
  String get labelSettingsOSTitle => 'OS';

  @override
  String get labelSettingsOSSubtitle => '文字制限等の設定';

  @override
  String get labelSettingsOSAuto => '自動';

  @override
  String get labelSettingsInitDirTitle => '起動時の場所';

  @override
  String get labelSettingsInitDirLast => '前回終了時';

  @override
  String get labelSettingsInitDirFixed => '指定場所';

  @override
  String get labelSettingsClearHistory => '履歴削除';

  @override
  String get labelSettingsClearHistorySub => '入力履歴を消去';

  @override
  String get labelSettingsResetAll => '全リセット';

  @override
  String get labelSettingsResetAllSub => '初期化します';

  @override
  String get labelSettingsBetaTitle => 'Beta機能';

  @override
  String get labelSettingsBetaSubtitle => '実験的機能を有効化';

  @override
  String get labelDialogCancel => 'キャンセル';

  @override
  String get labelDialogDelete => '削除';

  @override
  String get labelDialogReset => 'リセット';

  @override
  String get labelMsgHistoryCleared => '履歴を消去しました';

  @override
  String get labelMsgSettingsReset => 'リセットしました';

  @override
  String get labelFilterHideFolders => 'フォルダを隠す';

  @override
  String get labelFilterShowFolders => 'フォルダを表示';

  @override
  String get labelPreviewNoSelection => '未選択';

  @override
  String labelPreviewSelectedCount(int count) {
    return '$count 個選択中';
  }

  @override
  String get labelPreviewImageLoadFailed => '読込失敗';

  @override
  String get labelPreviewUnavailable => 'プレビュー不可';

  @override
  String labelPreviewOmitted(String size) {
    return '... ($size KB)';
  }

  @override
  String get labelPreviewBinaryError => 'プレビュー不可(Binary)';

  @override
  String get labelGoRenamery => '実行';

  @override
  String get labelTermFolder => 'フォルダ';

  @override
  String get labelTermFile => 'ファイル';

  @override
  String get labelTypeImage => '画像';

  @override
  String get labelTypePDF => 'PDF';

  @override
  String get labelTypeVideo => '動画';

  @override
  String get labelTypeAudio => '音楽';

  @override
  String get labelTypeDocument => '文書';

  @override
  String get labelTypeExecutable => 'アプリ';

  @override
  String get labelTypeArchive => '圧縮';

  @override
  String get labelTypeOther => '他';

  @override
  String get labelSettingsOSMac => 'Mac';

  @override
  String get labelSettingsOSLinux => 'Linux';

  @override
  String get labelSettingsOSiOS => 'iOS';

  @override
  String get labelSettingsOSAndroid => 'Android';

  @override
  String labelMsgExecutedCount(int count) {
    return '$count 個実行しました';
  }

  @override
  String get labelMsgNoSelection => '未選択です';

  @override
  String get labelCopyListPath => '現在の相対パスリストをコピー';

  @override
  String get labelMenuGo => '移動';

  @override
  String get labelNoFiles => 'ファイルなし';

  @override
  String labelSelectFolderPrompt(Object term) {
    return '$termを選択';
  }

  @override
  String get labelNavTitle => 'ナビゲーション';

  @override
  String get labelNavPC => 'PC';

  @override
  String get labelNumSaveSequenceTooltip => '連番を保存';

  @override
  String labelStatusDisplayCount(int current, int total, int selected) {
    return '表示: $current / 全 $total (選択 $selected)';
  }

  @override
  String labelStatusTotalCount(int total, int selected) {
    return '全 $total (選択 $selected)';
  }

  @override
  String get labelStatusProcessing => '処理中...';

  @override
  String get labelStatusReady => '待機中';

  @override
  String get labelDeleteConfirmTitle => '削除';

  @override
  String labelDeleteConfirmMessage(int count) {
    return '$count 個削除しますか？';
  }

  @override
  String labelMsgDeletedCount(int count) {
    return '$count 個削除しました';
  }

  @override
  String get labelUndoTitle => '戻す';

  @override
  String labelUndoConfirm(int count) {
    return '$count 件戻しますか？';
  }

  @override
  String get labelMsgUndoSuccess => '戻しました';

  @override
  String get labelUndoRecoverBtn => '戻す';

  @override
  String get labelMsgNoUndoRecord => '記録なし';

  @override
  String get labelMsgUndoRecordCopied => '記録をコピーしました';

  @override
  String labelMsgCopyNamesSuccess(int count) {
    return '$count 個コピー';
  }

  @override
  String labelMsgCopyFilesSuccess(int count) {
    return '$count 個コピー';
  }

  @override
  String labelMsgCutFilesSuccess(int count) {
    return '$count 個切取';
  }

  @override
  String labelMsgCopyRelativePathsSuccess(int count) {
    return '$count 個コピー';
  }

  @override
  String labelMsgCopyFullPathsSuccess(int count) {
    return '$count 個コピー';
  }

  @override
  String get labelSettingsAboutTitle => '情報';

  @override
  String get labelAboutVersion => 'Ver';

  @override
  String get labelAboutOriginal => 'オリジナル';

  @override
  String get labelAboutDev => '開発';

  @override
  String get labelAboutCopyright => '© 2024 Toyo Craft Lab.';

  @override
  String get labelAboutRespect => 'Original respect: Namery';

  @override
  String get labelAboutVisitWebsite => 'サイト表示';

  @override
  String get labelHistoryTooltip => '履歴';

  @override
  String get labelSettingsFolders => 'フォルダ';

  @override
  String get labelSettingsShowSystemFiles => 'システム表示';

  @override
  String get labelSettingsSystemFiles => 'システム';

  @override
  String get labelSettingsDisableRecursive => '再帰無効';

  @override
  String get labelSettingsRecursive => '下位フォルダ';

  @override
  String get labelDialogTrashTitle => '削除';

  @override
  String get labelDialogTrashMessage => 'ゴミ箱に移動しますか？';

  @override
  String get labelCtxPasteItems => '貼付';

  @override
  String get labelCtxCopyItems => 'コピー';

  @override
  String get labelCtxCutItems => '切取';

  @override
  String get labelCtxCreateFolder => '新規作成';

  @override
  String get labelFilterOptions => '検索と表示設定';

  @override
  String get labelMenuRenameSettings => 'リネーム設定';

  @override
  String get labelDialogClose => '閉じる';

  @override
  String get labelSearchHint => '検索...';

  @override
  String get labelRegexSearchHint => '正規表現で検索...';

  @override
  String get labelPermissionFileAccessTitle => 'ファイルアクセス権限';

  @override
  String get labelPermissionFileAccessMessage =>
      'このアプリでファイル名を変更するには、Android の設定で「すべてのファイルへのアクセス」を許可してください。\n\n次の画面で「ReNamery」を見つけて、スイッチを ON にしてください。';

  @override
  String get labelPermissionFileAccessButton => '設定を開く';

  @override
  String get labelLicenseAgreementTitle => '利用規約';

  @override
  String get labelLicenseAgreementMessage => '利用するには、以下のライセンス条項への同意が必要です。';

  @override
  String get labelLicenseDeclineExit => '同意しない（終了）';

  @override
  String get labelLicenseAcceptStart => '同意して開始';

  @override
  String get labelAppTitle => 'ReNamery - ファイル名を安全に一括変更 | 東洋クラフト';

  @override
  String labelUpdateAvailable(String version) {
    return '新しいVer (v$version) があります';
  }

  @override
  String get labelViewSettings => '設定を見る';

  @override
  String get labelLanguagePromptMessage => '表示言語はアプリ設定で変更できます。';

  @override
  String get labelLanguagePromptAction => '言語設定';

  @override
  String labelRecommendedLanguagePageMessage(String language, String url) {
    return 'ブラウザーの言語に合う$languageページがあります: $url';
  }

  @override
  String get labelRecommendedLanguagePageAction => '開く';

  @override
  String get labelAppExitTitle => '終了';

  @override
  String get labelAppExitConfirm => 'ReNamery を終了しますか？';

  @override
  String get labelExit => '終了';

  @override
  String get labelSkipInvalidTitle => 'エラーをスキップ';

  @override
  String labelSkipInvalidMessage(int invalidCount, int validCount) {
    return '不正な名前のファイルが $invalidCount 件あります。\n\n正常な $validCount 件だけリネームしますか？';
  }

  @override
  String get labelSkipAndContinue => 'スキップして続行';

  @override
  String labelMsgExecutedWithSkipped(int executedCount, int invalidCount) {
    return '$executedCount 件成功、$invalidCount 件スキップ';
  }

  @override
  String get labelMsgNoExecutableFiles => '実行できるファイルがありません';

  @override
  String get labelWebSelectFolderPromptTitle => 'ローカルフォルダを選択して開始';

  @override
  String get labelWebSelectFolderPromptMessage =>
      'Chrome系ブラウザで、選択したフォルダ内のファイル名をまとめて変更できます。';

  @override
  String get labelWebSelectFolderPromptPrivacy => 'データはデバイス以外に持ち出されることはありません。';

  @override
  String get labelWebSelectFolderPromptDesktopBeforeLink => 'シームレスな操作には、';

  @override
  String get labelDesktopAppVersionLink => 'デスクトップ・アプリ版';

  @override
  String get labelWebSelectFolderPromptDesktopAfterLink => 'をお勧めします。';

  @override
  String get labelWebUnsupportedPromptTitle => 'このブラウザでは利用できません';

  @override
  String get labelWebUnsupportedPromptMessage =>
      'ChromeまたはEdgeなどの対応ブラウザでお試しください。';

  @override
  String get labelSelectFolder => 'フォルダを選択';

  @override
  String get labelLicenseCannotExitTitle => '終了できません';

  @override
  String get labelLicenseCannotExitMessage =>
      'ブラウザではアプリ側からタブを閉じられません。使わない場合はタブを閉じてください。';

  @override
  String get labelDropOneFolder => 'フォルダを1つだけドロップしてください。';

  @override
  String get labelDropFolderNotFile => 'ファイルではなくフォルダを1つだけドロップしてください。';

  @override
  String get labelDropUnsupported => 'この環境ではフォルダD&Dに対応していません。';

  @override
  String get labelDropOpenFailed => 'フォルダを開けませんでした。';

  @override
  String get labelDropHereToOpen => 'ここにフォルダをドロップ';

  @override
  String get labelFileNotFound => 'ファイルがありません';

  @override
  String get labelWindowsPropertiesFailed => 'プロパティを開けませんでした';

  @override
  String labelPropertiesTitle(String name) {
    return 'プロパティ: $name';
  }

  @override
  String get labelPropertyKind => '種類';

  @override
  String get labelPropertyFileFolder => 'フォルダ';

  @override
  String get labelPropertyFile => 'ファイル';

  @override
  String get labelPropertyLocation => '場所';

  @override
  String get labelPropertySize => 'サイズ';

  @override
  String get labelPropertyModified => '更新日時';

  @override
  String get labelPropertyAttributes => '属性';

  @override
  String get labelWebUnsupportedBrowserMessage =>
      'このブラウザでは、ローカルフォルダ連携に必要な機能が利用できません。ChromeまたはEdgeなど、対応しているPC向けブラウザでお試しください。';

  @override
  String get labelWebLocalFolderPickerTitle => 'ローカルフォルダを選択';

  @override
  String get labelWebLocalFolderPickerSubtitle =>
      'Chrome / Edge などの対応ブラウザで利用できます';

  @override
  String get labelWebNoSavedDirectories => '選択済みフォルダはありません。';

  @override
  String get labelWebDirectoryPermissionDenied => 'フォルダへのアクセスが許可されませんでした。';

  @override
  String get labelWebAccessUnavailable =>
      'フォルダまたはファイルを読み込めませんでした。移動、削除、同期中などの可能性があります。';

  @override
  String get labelWebNameRequired => 'ファイル名を入力してください。';

  @override
  String get labelWebInvalidFileNameChars =>
      'ファイル名に使えない文字があります: / \\ : * ? \" < > |';

  @override
  String get labelWebDuplicateItem => '同じ名前の項目があります。';

  @override
  String get labelWebDuplicateFile => '同じ名前のファイルがあります。';

  @override
  String get labelWebItemAccessLost => '項目へのアクセス情報が失われました。フォルダを選択し直してください。';

  @override
  String get labelWebFileAccessLost => 'ファイルへのアクセス情報が失われました。フォルダを選択し直してください。';

  @override
  String get labelForgetQuickAccessTitle => 'クイックアクセスから解除しますか？';

  @override
  String labelForgetQuickAccessMessage(String name) {
    return '「$name」をReNameryのクイックアクセスから解除します。\n\nフォルダやファイル自体は削除されません。\n再度使う場合は「ローカルフォルダを選択」から追加してください。';
  }

  @override
  String get labelForget => '解除';

  @override
  String get labelForgetQuickAccessAction => 'クイックアクセスから解除';

  @override
  String get labelForgetQuickAccessSuccess =>
      'クイックアクセスから解除しました。ファイルは削除されていません。';

  @override
  String get labelForgetQuickAccessFailure => 'クイックアクセスから解除できませんでした。';

  @override
  String get labelArchiveContents => 'アーカイブ内容:';

  @override
  String labelPreviewError(String message) {
    return 'エラー: $message';
  }

  @override
  String labelPreviewUnsupportedWeb(String target) {
    return 'Web版では$targetの内容プレビューは未対応です。\n名前、種類、サイズなどは一覧で確認できます。';
  }

  @override
  String get labelPreviewTargetThisFile => 'このファイル';

  @override
  String labelPreviewTargetExtensionFile(String extension) {
    return '$extensionファイル';
  }

  @override
  String get labelScanConfirmTitle => 'スキャン確認';

  @override
  String labelScanConfirmCount(int count) {
    return '$count 件見つかりました。\n続行しますか？';
  }

  @override
  String labelScanConfirmTime(int count) {
    return 'スキャン開始から5秒経過しました（現在 $count 件）。\n続行しますか？';
  }

  @override
  String get labelScanConfirmStall => '応答が一時停止しています。続行しますか？';

  @override
  String get labelScanCancelClear => '中止 (クリア)';

  @override
  String get labelScanStopAndShow => 'ここで表示';

  @override
  String get labelScanContinue => '続行';
}
