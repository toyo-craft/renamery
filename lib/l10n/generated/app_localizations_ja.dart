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
  String get labelCopyFullPath => 'コピー (フルパス)';

  @override
  String get labelCopyOptions => 'コピーオプション';

  @override
  String get labelCopyUndo => '変更記録をコピー';

  @override
  String get labelCopyListClipboard => 'クリップボードへ現在のリストをコピー';

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
  String get labelCopyListPath => 'リストをクリップボードにコピー (Path)';

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
}

/// The translations for Japanese (`ja_NM`).
class AppLocalizationsJaNm extends AppLocalizationsJa {
  AppLocalizationsJaNm() : super('ja_NM');

  @override
  String get labelMainTab => 'Main';

  @override
  String get labelSubTab => 'Sub';

  @override
  String get labelExtraTab => 'Extra';

  @override
  String get labelEtcTab => 'etc...';

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
  String get labelColName => '名前';

  @override
  String get labelColNewName => '変更後ファイル名';

  @override
  String get labelColSize => 'サイズ';

  @override
  String get labelColPath => '相対パス';

  @override
  String get labelColType => 'ファイルの種類';

  @override
  String get labelColDate => '更新日時';

  @override
  String get labelColAttr => '属性';

  @override
  String get labelOpPrefix => 'Prefix(前方追加)';

  @override
  String get labelOpSuffix => 'Suffix(後方追加)';

  @override
  String get labelOpInsert => '文字列挿入';

  @override
  String get labelOpDeleteStart => '先頭から桁数分削除';

  @override
  String get labelOpDeleteEnd => '後ろから桁数分削除';

  @override
  String get labelOpDeleteFrom => '開始数字から桁数削除';

  @override
  String get labelOpCapitalize => '先頭文字を大文字化';

  @override
  String get labelOpUpper => '大文字化';

  @override
  String get labelOpLower => '小文字化';

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
  String get labelSubExtChangeTitle => 'Extension';

  @override
  String get labelSubFormatTitle => '英単語を区切って整形';

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
  String get labelSubListSample3 => 'Sample: Char Replace';

  @override
  String get labelSubListHint => 'old.txt\tnew.txt';

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
  String get labelEtcAttribReadOnly => 'ReadOnly';

  @override
  String get labelEtcAttribHidden => 'Hidden';

  @override
  String get labelEtcAttribArchive => 'Archive';

  @override
  String get labelEtcAttribSystem => 'System';

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
  String get labelCopyFullPath => 'コピー (フルパス)';

  @override
  String get labelCopyOptions => 'コピーオプション';

  @override
  String get labelCopyUndo => '変更記録をコピー';

  @override
  String get labelCopyListClipboard => 'クリップボードへ現在のリストをコピー';

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
  String get labelFullPath => 'フルパス > ';

  @override
  String get labelSelectAll => '全選択';

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
  String get labelSettingsLangCN => '中国';

  @override
  String get labelSettingsLangES => 'スペイン';

  @override
  String get labelSettingsThemeTitle => '見た目';

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
  String get labelCopyListPath => 'リストをクリップボードにコピー (Path)';

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
}
