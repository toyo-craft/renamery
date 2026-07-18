import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ja', 'NM'),
    Locale('zh')
  ];

  /// No description provided for @labelMainTab.
  ///
  /// In ja, this message translates to:
  /// **'基本'**
  String get labelMainTab;

  /// No description provided for @labelSubTab.
  ///
  /// In ja, this message translates to:
  /// **'拡張'**
  String get labelSubTab;

  /// No description provided for @labelExtraTab.
  ///
  /// In ja, this message translates to:
  /// **'高度'**
  String get labelExtraTab;

  /// No description provided for @labelEtcTab.
  ///
  /// In ja, this message translates to:
  /// **'属性'**
  String get labelEtcTab;

  /// No description provided for @labelCategoryAdd.
  ///
  /// In ja, this message translates to:
  /// **'テキストの追加'**
  String get labelCategoryAdd;

  /// No description provided for @labelCategoryRemove.
  ///
  /// In ja, this message translates to:
  /// **'テキストの削除'**
  String get labelCategoryRemove;

  /// No description provided for @labelCategoryReplace.
  ///
  /// In ja, this message translates to:
  /// **'置換と変換'**
  String get labelCategoryReplace;

  /// No description provided for @labelCategoryNumbering.
  ///
  /// In ja, this message translates to:
  /// **'連番 (ナンバリング)'**
  String get labelCategoryNumbering;

  /// No description provided for @labelCategoryExtension.
  ///
  /// In ja, this message translates to:
  /// **'拡張子'**
  String get labelCategoryExtension;

  /// No description provided for @labelCategoryAdvanced.
  ///
  /// In ja, this message translates to:
  /// **'高度な操作'**
  String get labelCategoryAdvanced;

  /// No description provided for @labelStringInput.
  ///
  /// In ja, this message translates to:
  /// **'文字列'**
  String get labelStringInput;

  /// No description provided for @labelColName.
  ///
  /// In ja, this message translates to:
  /// **'現在のファイル名'**
  String get labelColName;

  /// No description provided for @labelColNewName.
  ///
  /// In ja, this message translates to:
  /// **'新しいファイル名'**
  String get labelColNewName;

  /// No description provided for @labelColSize.
  ///
  /// In ja, this message translates to:
  /// **'サイズ'**
  String get labelColSize;

  /// No description provided for @labelColPath.
  ///
  /// In ja, this message translates to:
  /// **'パス'**
  String get labelColPath;

  /// No description provided for @labelColType.
  ///
  /// In ja, this message translates to:
  /// **'種別'**
  String get labelColType;

  /// No description provided for @labelColDate.
  ///
  /// In ja, this message translates to:
  /// **'更新日時'**
  String get labelColDate;

  /// No description provided for @labelColAttr.
  ///
  /// In ja, this message translates to:
  /// **'属性'**
  String get labelColAttr;

  /// No description provided for @labelOpPrefix.
  ///
  /// In ja, this message translates to:
  /// **'先頭に追加'**
  String get labelOpPrefix;

  /// No description provided for @labelOpSuffix.
  ///
  /// In ja, this message translates to:
  /// **'末尾に追加'**
  String get labelOpSuffix;

  /// No description provided for @labelOpInsert.
  ///
  /// In ja, this message translates to:
  /// **'指定位置に挿入'**
  String get labelOpInsert;

  /// No description provided for @labelOpDeleteStart.
  ///
  /// In ja, this message translates to:
  /// **'先頭から削除'**
  String get labelOpDeleteStart;

  /// No description provided for @labelOpDeleteEnd.
  ///
  /// In ja, this message translates to:
  /// **'末尾から削除'**
  String get labelOpDeleteEnd;

  /// No description provided for @labelOpDeleteFrom.
  ///
  /// In ja, this message translates to:
  /// **'指定位置から削除'**
  String get labelOpDeleteFrom;

  /// No description provided for @labelOpCapitalize.
  ///
  /// In ja, this message translates to:
  /// **'先頭を大文字化'**
  String get labelOpCapitalize;

  /// No description provided for @labelOpUpper.
  ///
  /// In ja, this message translates to:
  /// **'すべて大文字化'**
  String get labelOpUpper;

  /// No description provided for @labelOpLower.
  ///
  /// In ja, this message translates to:
  /// **'すべて小文字化'**
  String get labelOpLower;

  /// No description provided for @labelOpExtChange.
  ///
  /// In ja, this message translates to:
  /// **'拡張子を変更'**
  String get labelOpExtChange;

  /// No description provided for @labelOpExtAdd.
  ///
  /// In ja, this message translates to:
  /// **'拡張子を追加'**
  String get labelOpExtAdd;

  /// No description provided for @labelOpExtRemove.
  ///
  /// In ja, this message translates to:
  /// **'拡張子を削除'**
  String get labelOpExtRemove;

  /// No description provided for @labelOpExtUpper.
  ///
  /// In ja, this message translates to:
  /// **'拡張子を大文字化'**
  String get labelOpExtUpper;

  /// No description provided for @labelOpExtLower.
  ///
  /// In ja, this message translates to:
  /// **'拡張子を小文字化'**
  String get labelOpExtLower;

  /// No description provided for @labelSubExtChangeTitle.
  ///
  /// In ja, this message translates to:
  /// **'拡張子変更'**
  String get labelSubExtChangeTitle;

  /// No description provided for @labelSubFormatTitle.
  ///
  /// In ja, this message translates to:
  /// **'英単語整形'**
  String get labelSubFormatTitle;

  /// No description provided for @labelSubFormatProperCase.
  ///
  /// In ja, this message translates to:
  /// **'単語の先頭を大文字化 (Space/Hyphen/Underscore)'**
  String get labelSubFormatProperCase;

  /// No description provided for @labelSubListTitle.
  ///
  /// In ja, this message translates to:
  /// **'文字列リネーム'**
  String get labelSubListTitle;

  /// No description provided for @labelSubListModeText.
  ///
  /// In ja, this message translates to:
  /// **'テキスト入力 (Original[TAB]New)'**
  String get labelSubListModeText;

  /// No description provided for @labelSubListSample1.
  ///
  /// In ja, this message translates to:
  /// **'サンプル: 連番ファイル'**
  String get labelSubListSample1;

  /// No description provided for @labelSubListSample2.
  ///
  /// In ja, this message translates to:
  /// **'サンプル: 拡張子一括置換'**
  String get labelSubListSample2;

  /// No description provided for @labelSubListSample3.
  ///
  /// In ja, this message translates to:
  /// **'サンプル: 特定文字の置換'**
  String get labelSubListSample3;

  /// No description provided for @labelSubListHint.
  ///
  /// In ja, this message translates to:
  /// **'old_name.txt\tnew_name.txt\nfile01.png\timage01.png'**
  String get labelSubListHint;

  /// No description provided for @labelExtraAppendDate.
  ///
  /// In ja, this message translates to:
  /// **'ファイルの日付を付加'**
  String get labelExtraAppendDate;

  /// No description provided for @labelExtraDateFormatHint.
  ///
  /// In ja, this message translates to:
  /// **'日付フォーマット (例: yyyymmdd_)'**
  String get labelExtraDateFormatHint;

  /// No description provided for @labelExtraPosition.
  ///
  /// In ja, this message translates to:
  /// **'位置'**
  String get labelExtraPosition;

  /// No description provided for @labelExtraFront.
  ///
  /// In ja, this message translates to:
  /// **'前方'**
  String get labelExtraFront;

  /// No description provided for @labelExtraBack.
  ///
  /// In ja, this message translates to:
  /// **'後方'**
  String get labelExtraBack;

  /// No description provided for @labelExtraConvHalfToFull.
  ///
  /// In ja, this message translates to:
  /// **'半角を全角にする'**
  String get labelExtraConvHalfToFull;

  /// No description provided for @labelExtraConvFullToHalf.
  ///
  /// In ja, this message translates to:
  /// **'全角を半角にする'**
  String get labelExtraConvFullToHalf;

  /// No description provided for @labelExtraConvKataToHira.
  ///
  /// In ja, this message translates to:
  /// **'全角カナをひらがなにする'**
  String get labelExtraConvKataToHira;

  /// No description provided for @labelExtraConvHiraToKata.
  ///
  /// In ja, this message translates to:
  /// **'ひらがなを全角カナにする'**
  String get labelExtraConvHiraToKata;

  /// No description provided for @labelExtraConvFullAlphaToHalf.
  ///
  /// In ja, this message translates to:
  /// **'全角英字を半角にする'**
  String get labelExtraConvFullAlphaToHalf;

  /// No description provided for @labelExtraConvNumToHalf.
  ///
  /// In ja, this message translates to:
  /// **'数字を半角にする'**
  String get labelExtraConvNumToHalf;

  /// No description provided for @labelEtcAttribReadOnly.
  ///
  /// In ja, this message translates to:
  /// **'読み取り専用'**
  String get labelEtcAttribReadOnly;

  /// No description provided for @labelEtcAttribHidden.
  ///
  /// In ja, this message translates to:
  /// **'隠しファイル'**
  String get labelEtcAttribHidden;

  /// No description provided for @labelEtcAttribArchive.
  ///
  /// In ja, this message translates to:
  /// **'アーカイブ'**
  String get labelEtcAttribArchive;

  /// No description provided for @labelEtcAttribSystem.
  ///
  /// In ja, this message translates to:
  /// **'システムファイル'**
  String get labelEtcAttribSystem;

  /// No description provided for @labelEtcTimestampChange.
  ///
  /// In ja, this message translates to:
  /// **'タイムスタンプを変更する'**
  String get labelEtcTimestampChange;

  /// No description provided for @labelEtcPickTime.
  ///
  /// In ja, this message translates to:
  /// **'時刻を選択してください'**
  String get labelEtcPickTime;

  /// No description provided for @labelEtcPickDateTooltip.
  ///
  /// In ja, this message translates to:
  /// **'日付と時刻を選択'**
  String get labelEtcPickDateTooltip;

  /// No description provided for @labelEtcTimestampNote.
  ///
  /// In ja, this message translates to:
  /// **'(Ex 2002/03/30 17:30 のように指定します。)'**
  String get labelEtcTimestampNote;

  /// No description provided for @labelEtcAttributeChange.
  ///
  /// In ja, this message translates to:
  /// **'属性を変更する'**
  String get labelEtcAttributeChange;

  /// No description provided for @labelEtcCautionTitle.
  ///
  /// In ja, this message translates to:
  /// **'取り消し操作不能'**
  String get labelEtcCautionTitle;

  /// No description provided for @labelEtcCautionMessage.
  ///
  /// In ja, this message translates to:
  /// **'このカテゴリ（タイムスタンプ・属性）の変更は、アンドゥ機能で元に戻すことができません。慎重に操作してください。'**
  String get labelEtcCautionMessage;

  /// No description provided for @labelUndo.
  ///
  /// In ja, this message translates to:
  /// **'戻す'**
  String get labelUndo;

  /// No description provided for @labelExecute.
  ///
  /// In ja, this message translates to:
  /// **'実行'**
  String get labelExecute;

  /// No description provided for @labelErrorInvalidFilename.
  ///
  /// In ja, this message translates to:
  /// **'エラー：ファイル名に禁止文字が含まれています'**
  String get labelErrorInvalidFilename;

  /// No description provided for @labelCopyName.
  ///
  /// In ja, this message translates to:
  /// **'コピー (現在名)'**
  String get labelCopyName;

  /// No description provided for @labelCopyPath.
  ///
  /// In ja, this message translates to:
  /// **'コピー (パス)'**
  String get labelCopyPath;

  /// No description provided for @labelCopyFullPath.
  ///
  /// In ja, this message translates to:
  /// **'現在のフルパスリストをコピー'**
  String get labelCopyFullPath;

  /// No description provided for @labelCopyOptions.
  ///
  /// In ja, this message translates to:
  /// **'現在のリストをコピー'**
  String get labelCopyOptions;

  /// No description provided for @labelCopyUndo.
  ///
  /// In ja, this message translates to:
  /// **'リネーム後のファイル名リストをコピー'**
  String get labelCopyUndo;

  /// No description provided for @labelCopyListClipboard.
  ///
  /// In ja, this message translates to:
  /// **'現在のファイル名リストをコピー'**
  String get labelCopyListClipboard;

  /// No description provided for @labelMoveUp.
  ///
  /// In ja, this message translates to:
  /// **'上に移動'**
  String get labelMoveUp;

  /// No description provided for @labelMoveDown.
  ///
  /// In ja, this message translates to:
  /// **'下に移動'**
  String get labelMoveDown;

  /// No description provided for @labelRefresh.
  ///
  /// In ja, this message translates to:
  /// **'全て更新'**
  String get labelRefresh;

  /// No description provided for @labelMenuMore.
  ///
  /// In ja, this message translates to:
  /// **'その他の操作'**
  String get labelMenuMore;

  /// No description provided for @labelMenuSettings.
  ///
  /// In ja, this message translates to:
  /// **'アプリ設定'**
  String get labelMenuSettings;

  /// No description provided for @labelMenuFolder.
  ///
  /// In ja, this message translates to:
  /// **'メニュー (フォルダ)'**
  String get labelMenuFolder;

  /// No description provided for @labelNumStringNumber.
  ///
  /// In ja, this message translates to:
  /// **'文字列 + 連番'**
  String get labelNumStringNumber;

  /// No description provided for @labelNumOriginalNumber.
  ///
  /// In ja, this message translates to:
  /// **'現在名 + 連番'**
  String get labelNumOriginalNumber;

  /// No description provided for @labelNumNumberString.
  ///
  /// In ja, this message translates to:
  /// **'連番 + 文字列'**
  String get labelNumNumberString;

  /// No description provided for @labelNumNumberOriginal.
  ///
  /// In ja, this message translates to:
  /// **'連番 + 現在名'**
  String get labelNumNumberOriginal;

  /// No description provided for @labelNumBaseStringNumber.
  ///
  /// In ja, this message translates to:
  /// **'基本名 + 文字列 + 連番'**
  String get labelNumBaseStringNumber;

  /// No description provided for @labelNumBaseStringOriginal.
  ///
  /// In ja, this message translates to:
  /// **'基本名 + 文字列 + 現在名'**
  String get labelNumBaseStringOriginal;

  /// No description provided for @labelNumRelativeStringNumber.
  ///
  /// In ja, this message translates to:
  /// **'相対名 + 文字列 + 連番'**
  String get labelNumRelativeStringNumber;

  /// No description provided for @labelNumRelativeStringOriginal.
  ///
  /// In ja, this message translates to:
  /// **'相対名 + 文字列 + 現在名'**
  String get labelNumRelativeStringOriginal;

  /// No description provided for @labelNumNumberStringBase.
  ///
  /// In ja, this message translates to:
  /// **'連番 + 文字列 + 基本名'**
  String get labelNumNumberStringBase;

  /// No description provided for @labelNumNumberStringRelative.
  ///
  /// In ja, this message translates to:
  /// **'連番 + 文字列 + 相対名'**
  String get labelNumNumberStringRelative;

  /// No description provided for @labelReplaceFrom.
  ///
  /// In ja, this message translates to:
  /// **'を'**
  String get labelReplaceFrom;

  /// No description provided for @labelReplaceTo.
  ///
  /// In ja, this message translates to:
  /// **'に置換'**
  String get labelReplaceTo;

  /// No description provided for @labelFullPath.
  ///
  /// In ja, this message translates to:
  /// **'現在の場所 > '**
  String get labelFullPath;

  /// No description provided for @labelSelectAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて選択'**
  String get labelSelectAll;

  /// No description provided for @labelDeselectAll.
  ///
  /// In ja, this message translates to:
  /// **'選択解除'**
  String get labelDeselectAll;

  /// No description provided for @labelSettingsFilterTitle.
  ///
  /// In ja, this message translates to:
  /// **'表示設定 (フィルタ)'**
  String get labelSettingsFilterTitle;

  /// No description provided for @labelFilterAll.
  ///
  /// In ja, this message translates to:
  /// **'全てのファイル'**
  String get labelFilterAll;

  /// No description provided for @labelFilterSpecific.
  ///
  /// In ja, this message translates to:
  /// **'指定'**
  String get labelFilterSpecific;

  /// No description provided for @labelFilterHideSystem.
  ///
  /// In ja, this message translates to:
  /// **'システムファイルを非表示'**
  String get labelFilterHideSystem;

  /// No description provided for @labelFilterRecursive.
  ///
  /// In ja, this message translates to:
  /// **'下位フォルダ検索'**
  String get labelFilterRecursive;

  /// No description provided for @labelBetaListRenameHint.
  ///
  /// In ja, this message translates to:
  /// **'※ ベータ版が有効なため表示されています'**
  String get labelBetaListRenameHint;

  /// No description provided for @labelCtxUpOneFolder.
  ///
  /// In ja, this message translates to:
  /// **'一つ上のフォルダへ'**
  String get labelCtxUpOneFolder;

  /// No description provided for @labelCtxRenameGeneral.
  ///
  /// In ja, this message translates to:
  /// **'名前の変更 (一般)'**
  String get labelCtxRenameGeneral;

  /// No description provided for @labelCtxBatchRename.
  ///
  /// In ja, this message translates to:
  /// **'一括変更 (Namery)'**
  String get labelCtxBatchRename;

  /// No description provided for @labelCtxOpenWithAssoc.
  ///
  /// In ja, this message translates to:
  /// **'関連付けで開く'**
  String get labelCtxOpenWithAssoc;

  /// No description provided for @labelCtxMoveToTop.
  ///
  /// In ja, this message translates to:
  /// **'選択項目を先頭に移動'**
  String get labelCtxMoveToTop;

  /// No description provided for @labelCtxMoveToBottom.
  ///
  /// In ja, this message translates to:
  /// **'選択項目を最後尾に移動'**
  String get labelCtxMoveToBottom;

  /// No description provided for @labelCtxDeleteItems.
  ///
  /// In ja, this message translates to:
  /// **'選択項目を削除 (Del)'**
  String get labelCtxDeleteItems;

  /// No description provided for @labelCtxMoveCaret.
  ///
  /// In ja, this message translates to:
  /// **'キャレット移動'**
  String get labelCtxMoveCaret;

  /// No description provided for @labelCtxCaretSettings.
  ///
  /// In ja, this message translates to:
  /// **'キャレットの設定'**
  String get labelCtxCaretSettings;

  /// No description provided for @labelCtxRefresh.
  ///
  /// In ja, this message translates to:
  /// **'最新の情報に更新 (F5)'**
  String get labelCtxRefresh;

  /// No description provided for @labelCtxProperties.
  ///
  /// In ja, this message translates to:
  /// **'プロパティ(R)'**
  String get labelCtxProperties;

  /// No description provided for @labelFilterPreview.
  ///
  /// In ja, this message translates to:
  /// **'プレビュー表示'**
  String get labelFilterPreview;

  /// No description provided for @labelExtensionLower.
  ///
  /// In ja, this message translates to:
  /// **'拡張子は小文字化'**
  String get labelExtensionLower;

  /// No description provided for @labelNavBack.
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get labelNavBack;

  /// No description provided for @labelNavForward.
  ///
  /// In ja, this message translates to:
  /// **'進む'**
  String get labelNavForward;

  /// No description provided for @labelNavUp.
  ///
  /// In ja, this message translates to:
  /// **'一つ上のフォルダへ'**
  String get labelNavUp;

  /// No description provided for @labelNavHistory.
  ///
  /// In ja, this message translates to:
  /// **'履歴'**
  String get labelNavHistory;

  /// No description provided for @labelNoHistory.
  ///
  /// In ja, this message translates to:
  /// **'履歴がありません'**
  String get labelNoHistory;

  /// No description provided for @labelScanStop.
  ///
  /// In ja, this message translates to:
  /// **'スキャン停止'**
  String get labelScanStop;

  /// No description provided for @labelHistoryBack.
  ///
  /// In ja, this message translates to:
  /// **'履歴 (戻る)'**
  String get labelHistoryBack;

  /// No description provided for @labelHistoryForward.
  ///
  /// In ja, this message translates to:
  /// **'履歴 (進む)'**
  String get labelHistoryForward;

  /// No description provided for @labelNavQuickAccess.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクセス'**
  String get labelNavQuickAccess;

  /// No description provided for @labelDeleteFront.
  ///
  /// In ja, this message translates to:
  /// **'前から'**
  String get labelDeleteFront;

  /// No description provided for @labelDeleteBack.
  ///
  /// In ja, this message translates to:
  /// **'後から'**
  String get labelDeleteBack;

  /// No description provided for @labelDeleteUntil.
  ///
  /// In ja, this message translates to:
  /// **'まで削除'**
  String get labelDeleteUntil;

  /// No description provided for @labelFindHint.
  ///
  /// In ja, this message translates to:
  /// **'検索 (Find)'**
  String get labelFindHint;

  /// No description provided for @labelReplaceHint.
  ///
  /// In ja, this message translates to:
  /// **'置換 (Replace)'**
  String get labelReplaceHint;

  /// No description provided for @labelRegex.
  ///
  /// In ja, this message translates to:
  /// **'正規表現'**
  String get labelRegex;

  /// No description provided for @labelString.
  ///
  /// In ja, this message translates to:
  /// **'文字列'**
  String get labelString;

  /// No description provided for @labelStartDigit.
  ///
  /// In ja, this message translates to:
  /// **'開始/桁'**
  String get labelStartDigit;

  /// No description provided for @labelStart.
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get labelStart;

  /// No description provided for @labelDigit.
  ///
  /// In ja, this message translates to:
  /// **'桁'**
  String get labelDigit;

  /// No description provided for @labelSettingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get labelSettingsTitle;

  /// No description provided for @labelSettingsSectionDisplay.
  ///
  /// In ja, this message translates to:
  /// **'表示設定'**
  String get labelSettingsSectionDisplay;

  /// No description provided for @labelSettingsSectionAppearance.
  ///
  /// In ja, this message translates to:
  /// **'外観'**
  String get labelSettingsSectionAppearance;

  /// No description provided for @labelSettingsSectionOS.
  ///
  /// In ja, this message translates to:
  /// **'動作モード (OS設定)'**
  String get labelSettingsSectionOS;

  /// No description provided for @labelSettingsSectionInitialDir.
  ///
  /// In ja, this message translates to:
  /// **'初期フォルダ'**
  String get labelSettingsSectionInitialDir;

  /// No description provided for @labelSettingsSectionReset.
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get labelSettingsSectionReset;

  /// No description provided for @labelSettingsTouchModeTitle.
  ///
  /// In ja, this message translates to:
  /// **'タッチモード (ゆったり表示)'**
  String get labelSettingsTouchModeTitle;

  /// No description provided for @labelSettingsTouchModeSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'リストやボタンの間隔を広げます'**
  String get labelSettingsTouchModeSubtitle;

  /// No description provided for @labelSettingsMenuLabelTitle.
  ///
  /// In ja, this message translates to:
  /// **'メニュー表記 (言語)'**
  String get labelSettingsMenuLabelTitle;

  /// No description provided for @labelSettingsLangJP.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get labelSettingsLangJP;

  /// No description provided for @labelSettingsLangNamery.
  ///
  /// In ja, this message translates to:
  /// **'Namery'**
  String get labelSettingsLangNamery;

  /// No description provided for @labelSettingsLangEN.
  ///
  /// In ja, this message translates to:
  /// **'英語'**
  String get labelSettingsLangEN;

  /// No description provided for @labelSettingsLangCN.
  ///
  /// In ja, this message translates to:
  /// **'中国語'**
  String get labelSettingsLangCN;

  /// No description provided for @labelSettingsLangES.
  ///
  /// In ja, this message translates to:
  /// **'スペイン語'**
  String get labelSettingsLangES;

  /// No description provided for @labelSettingsThemeTitle.
  ///
  /// In ja, this message translates to:
  /// **'テーマモード'**
  String get labelSettingsThemeTitle;

  /// No description provided for @labelSettingsThemeSystem.
  ///
  /// In ja, this message translates to:
  /// **'システム'**
  String get labelSettingsThemeSystem;

  /// No description provided for @labelSettingsThemeLight.
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get labelSettingsThemeLight;

  /// No description provided for @labelSettingsThemeDark.
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get labelSettingsThemeDark;

  /// No description provided for @labelSettingsThemeGray.
  ///
  /// In ja, this message translates to:
  /// **'グレー'**
  String get labelSettingsThemeGray;

  /// No description provided for @labelSettingsColorTitle.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラー'**
  String get labelSettingsColorTitle;

  /// No description provided for @labelSettingsOSTitle.
  ///
  /// In ja, this message translates to:
  /// **'OSモード'**
  String get labelSettingsOSTitle;

  /// No description provided for @labelSettingsOSSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'ファイル名の文字制限などをOSに合わせます'**
  String get labelSettingsOSSubtitle;

  /// No description provided for @labelSettingsOSAuto.
  ///
  /// In ja, this message translates to:
  /// **'自動'**
  String get labelSettingsOSAuto;

  /// No description provided for @labelSettingsInitDirTitle.
  ///
  /// In ja, this message translates to:
  /// **'起動時の場所'**
  String get labelSettingsInitDirTitle;

  /// No description provided for @labelSettingsInitDirLast.
  ///
  /// In ja, this message translates to:
  /// **'前回終了時の場所'**
  String get labelSettingsInitDirLast;

  /// No description provided for @labelSettingsInitDirFixed.
  ///
  /// In ja, this message translates to:
  /// **'指定した場所'**
  String get labelSettingsInitDirFixed;

  /// No description provided for @labelSettingsClearHistory.
  ///
  /// In ja, this message translates to:
  /// **'入力履歴を削除'**
  String get labelSettingsClearHistory;

  /// No description provided for @labelSettingsClearHistorySub.
  ///
  /// In ja, this message translates to:
  /// **'文字列補完などの入力履歴を削除します'**
  String get labelSettingsClearHistorySub;

  /// No description provided for @labelSettingsResetAll.
  ///
  /// In ja, this message translates to:
  /// **'全設定をリセット'**
  String get labelSettingsResetAll;

  /// No description provided for @labelSettingsResetAllSub.
  ///
  /// In ja, this message translates to:
  /// **'初期状態に戻します'**
  String get labelSettingsResetAllSub;

  /// No description provided for @labelSettingsBetaTitle.
  ///
  /// In ja, this message translates to:
  /// **'Beta版機能を有効にする'**
  String get labelSettingsBetaTitle;

  /// No description provided for @labelSettingsBetaSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'テスト中の新機能を表示します（例：リストリネーム）'**
  String get labelSettingsBetaSubtitle;

  /// No description provided for @labelDialogCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get labelDialogCancel;

  /// No description provided for @labelDialogDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get labelDialogDelete;

  /// No description provided for @labelDialogReset.
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get labelDialogReset;

  /// No description provided for @labelMsgHistoryCleared.
  ///
  /// In ja, this message translates to:
  /// **'履歴を削除しました'**
  String get labelMsgHistoryCleared;

  /// No description provided for @labelMsgSettingsReset.
  ///
  /// In ja, this message translates to:
  /// **'設定をリセットしました'**
  String get labelMsgSettingsReset;

  /// No description provided for @labelFilterHideFolders.
  ///
  /// In ja, this message translates to:
  /// **'フォルダーを隠す'**
  String get labelFilterHideFolders;

  /// No description provided for @labelFilterShowFolders.
  ///
  /// In ja, this message translates to:
  /// **'フォルダーを表示'**
  String get labelFilterShowFolders;

  /// No description provided for @labelPreviewNoSelection.
  ///
  /// In ja, this message translates to:
  /// **'選択されていません'**
  String get labelPreviewNoSelection;

  /// No description provided for @labelPreviewSelectedCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 個のファイルが選択されています'**
  String labelPreviewSelectedCount(int count);

  /// No description provided for @labelPreviewImageLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'画像の読み込みに失敗しました'**
  String get labelPreviewImageLoadFailed;

  /// No description provided for @labelPreviewUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'プレビューを利用できません'**
  String get labelPreviewUnavailable;

  /// No description provided for @labelPreviewOmitted.
  ///
  /// In ja, this message translates to:
  /// **'... (省略されました: 全 {size} KB)'**
  String labelPreviewOmitted(String size);

  /// No description provided for @labelPreviewBinaryError.
  ///
  /// In ja, this message translates to:
  /// **'プレビューを利用できません: バイナリまたは不明なエンコーディング'**
  String get labelPreviewBinaryError;

  /// No description provided for @labelGoRenamery.
  ///
  /// In ja, this message translates to:
  /// **'リネームを実行'**
  String get labelGoRenamery;

  /// No description provided for @labelTermFolder.
  ///
  /// In ja, this message translates to:
  /// **'フォルダー'**
  String get labelTermFolder;

  /// No description provided for @labelTermFile.
  ///
  /// In ja, this message translates to:
  /// **'ファイル'**
  String get labelTermFile;

  /// No description provided for @labelTypeImage.
  ///
  /// In ja, this message translates to:
  /// **'画像'**
  String get labelTypeImage;

  /// No description provided for @labelTypePDF.
  ///
  /// In ja, this message translates to:
  /// **'PDF'**
  String get labelTypePDF;

  /// No description provided for @labelTypeVideo.
  ///
  /// In ja, this message translates to:
  /// **'動画'**
  String get labelTypeVideo;

  /// No description provided for @labelTypeAudio.
  ///
  /// In ja, this message translates to:
  /// **'音楽'**
  String get labelTypeAudio;

  /// No description provided for @labelTypeDocument.
  ///
  /// In ja, this message translates to:
  /// **'文書'**
  String get labelTypeDocument;

  /// No description provided for @labelTypeExecutable.
  ///
  /// In ja, this message translates to:
  /// **'アプリ'**
  String get labelTypeExecutable;

  /// No description provided for @labelTypeArchive.
  ///
  /// In ja, this message translates to:
  /// **'圧縮'**
  String get labelTypeArchive;

  /// No description provided for @labelTypeOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get labelTypeOther;

  /// No description provided for @labelSettingsOSMac.
  ///
  /// In ja, this message translates to:
  /// **'Mac (Finder互換)'**
  String get labelSettingsOSMac;

  /// No description provided for @labelSettingsOSLinux.
  ///
  /// In ja, this message translates to:
  /// **'Linux'**
  String get labelSettingsOSLinux;

  /// No description provided for @labelSettingsOSiOS.
  ///
  /// In ja, this message translates to:
  /// **'iOS (iPhone/iPad)'**
  String get labelSettingsOSiOS;

  /// No description provided for @labelSettingsOSAndroid.
  ///
  /// In ja, this message translates to:
  /// **'Android'**
  String get labelSettingsOSAndroid;

  /// No description provided for @labelMsgExecutedCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 個のファイルをリネームしました'**
  String labelMsgExecutedCount(int count);

  /// No description provided for @labelMsgNoSelection.
  ///
  /// In ja, this message translates to:
  /// **'ファイルが選択されていません'**
  String get labelMsgNoSelection;

  /// No description provided for @labelCopyListPath.
  ///
  /// In ja, this message translates to:
  /// **'現在の相対パスリストをコピー'**
  String get labelCopyListPath;

  /// No description provided for @labelMenuGo.
  ///
  /// In ja, this message translates to:
  /// **'移動'**
  String get labelMenuGo;

  /// No description provided for @labelNoFiles.
  ///
  /// In ja, this message translates to:
  /// **'ファイルがありません'**
  String get labelNoFiles;

  /// No description provided for @labelSelectFolderPrompt.
  ///
  /// In ja, this message translates to:
  /// **'{term}を選択してください'**
  String labelSelectFolderPrompt(Object term);

  /// No description provided for @labelNavTitle.
  ///
  /// In ja, this message translates to:
  /// **'ナビゲーション'**
  String get labelNavTitle;

  /// No description provided for @labelNavPC.
  ///
  /// In ja, this message translates to:
  /// **'PC'**
  String get labelNavPC;

  /// No description provided for @labelNumSaveSequenceTooltip.
  ///
  /// In ja, this message translates to:
  /// **'変更後の連番数字を保存（次回リネーム時に連番を継続）'**
  String get labelNumSaveSequenceTooltip;

  /// No description provided for @labelStatusDisplayCount.
  ///
  /// In ja, this message translates to:
  /// **'現在の表示: {current} / 全 {total} ファイル : 選択 {selected} ファイル'**
  String labelStatusDisplayCount(int current, int total, int selected);

  /// No description provided for @labelStatusTotalCount.
  ///
  /// In ja, this message translates to:
  /// **'全 {total} ファイル : 選択 {selected} ファイル'**
  String labelStatusTotalCount(int total, int selected);

  /// No description provided for @labelStatusProcessing.
  ///
  /// In ja, this message translates to:
  /// **'処理中...'**
  String get labelStatusProcessing;

  /// No description provided for @labelStatusReady.
  ///
  /// In ja, this message translates to:
  /// **'準備完了'**
  String get labelStatusReady;

  /// No description provided for @labelDeleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除の確認'**
  String get labelDeleteConfirmTitle;

  /// No description provided for @labelDeleteConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'{count} 個のファイルを完全に削除しますか？\nこの操作は元に戻せません。'**
  String labelDeleteConfirmMessage(int count);

  /// No description provided for @labelMsgDeletedCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 個のファイルを削除しました'**
  String labelMsgDeletedCount(int count);

  /// No description provided for @labelUndoTitle.
  ///
  /// In ja, this message translates to:
  /// **'処理の復元'**
  String get labelUndoTitle;

  /// No description provided for @labelUndoConfirm.
  ///
  /// In ja, this message translates to:
  /// **'直前に行った {count} 件の変更を元に戻しますか？'**
  String labelUndoConfirm(int count);

  /// No description provided for @labelMsgUndoSuccess.
  ///
  /// In ja, this message translates to:
  /// **'復元しました'**
  String get labelMsgUndoSuccess;

  /// No description provided for @labelUndoRecoverBtn.
  ///
  /// In ja, this message translates to:
  /// **'復元'**
  String get labelUndoRecoverBtn;

  /// No description provided for @labelMsgNoUndoRecord.
  ///
  /// In ja, this message translates to:
  /// **'直前の変更記録がありません'**
  String get labelMsgNoUndoRecord;

  /// No description provided for @labelMsgUndoRecordCopied.
  ///
  /// In ja, this message translates to:
  /// **'直前の変更記録をクリップボードにコピーしました'**
  String get labelMsgUndoRecordCopied;

  /// No description provided for @labelMsgCopyNamesSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count} 件のファイル名をコピーしました'**
  String labelMsgCopyNamesSuccess(int count);

  /// No description provided for @labelMsgCopyFilesSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count} 件のファイルをコピーしました'**
  String labelMsgCopyFilesSuccess(int count);

  /// No description provided for @labelMsgCutFilesSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count} 件のファイルを切り取りました'**
  String labelMsgCutFilesSuccess(int count);

  /// No description provided for @labelMsgCopyRelativePathsSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count} 件のファイルパス(相対)をコピーしました'**
  String labelMsgCopyRelativePathsSuccess(int count);

  /// No description provided for @labelMsgCopyFullPathsSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count} 件のフルパスをコピーしました'**
  String labelMsgCopyFullPathsSuccess(int count);

  /// No description provided for @labelSettingsAboutTitle.
  ///
  /// In ja, this message translates to:
  /// **'アプリについて'**
  String get labelSettingsAboutTitle;

  /// No description provided for @labelAboutVersion.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get labelAboutVersion;

  /// No description provided for @labelAboutOriginal.
  ///
  /// In ja, this message translates to:
  /// **'原案・オリジナル'**
  String get labelAboutOriginal;

  /// No description provided for @labelAboutDev.
  ///
  /// In ja, this message translates to:
  /// **'企画・開発'**
  String get labelAboutDev;

  /// No description provided for @labelAboutCopyright.
  ///
  /// In ja, this message translates to:
  /// **'© 2024 Toyo Craft Lab.'**
  String get labelAboutCopyright;

  /// No description provided for @labelAboutRespect.
  ///
  /// In ja, this message translates to:
  /// **'当アプリは、Jun Arai 様の \'Namery\' をリスペクトして作成されました。'**
  String get labelAboutRespect;

  /// No description provided for @labelAboutVisitWebsite.
  ///
  /// In ja, this message translates to:
  /// **'ウェブサイトを表示'**
  String get labelAboutVisitWebsite;

  /// No description provided for @labelHistoryTooltip.
  ///
  /// In ja, this message translates to:
  /// **'履歴を表示'**
  String get labelHistoryTooltip;

  /// No description provided for @labelSettingsFolders.
  ///
  /// In ja, this message translates to:
  /// **'フォルダ表示'**
  String get labelSettingsFolders;

  /// No description provided for @labelSettingsShowSystemFiles.
  ///
  /// In ja, this message translates to:
  /// **'システムファイルを表示'**
  String get labelSettingsShowSystemFiles;

  /// No description provided for @labelSettingsSystemFiles.
  ///
  /// In ja, this message translates to:
  /// **'システムファイル'**
  String get labelSettingsSystemFiles;

  /// No description provided for @labelSettingsDisableRecursive.
  ///
  /// In ja, this message translates to:
  /// **'下位フォルダ検索を無効'**
  String get labelSettingsDisableRecursive;

  /// No description provided for @labelSettingsRecursive.
  ///
  /// In ja, this message translates to:
  /// **'下位フォルダ'**
  String get labelSettingsRecursive;

  /// No description provided for @labelDialogTrashTitle.
  ///
  /// In ja, this message translates to:
  /// **'項目の削除'**
  String get labelDialogTrashTitle;

  /// No description provided for @labelDialogTrashMessage.
  ///
  /// In ja, this message translates to:
  /// **'選択したファイルをゴミ箱に移動しますか？'**
  String get labelDialogTrashMessage;

  /// No description provided for @labelCtxPasteItems.
  ///
  /// In ja, this message translates to:
  /// **'項目を貼り付け'**
  String get labelCtxPasteItems;

  /// No description provided for @labelCtxCopyItems.
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get labelCtxCopyItems;

  /// No description provided for @labelCtxCutItems.
  ///
  /// In ja, this message translates to:
  /// **'切り取り'**
  String get labelCtxCutItems;

  /// No description provided for @labelCtxCreateFolder.
  ///
  /// In ja, this message translates to:
  /// **'新しいフォルダーの作成'**
  String get labelCtxCreateFolder;

  /// No description provided for @labelFilterOptions.
  ///
  /// In ja, this message translates to:
  /// **'検索と表示設定'**
  String get labelFilterOptions;

  /// No description provided for @labelMenuRenameSettings.
  ///
  /// In ja, this message translates to:
  /// **'リネーム設定'**
  String get labelMenuRenameSettings;

  /// No description provided for @labelDialogClose.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get labelDialogClose;

  /// No description provided for @labelSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'ファイル名で検索...'**
  String get labelSearchHint;

  /// No description provided for @labelRegexSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'正規表現で検索...'**
  String get labelRegexSearchHint;

  /// No description provided for @labelPermissionFileAccessTitle.
  ///
  /// In ja, this message translates to:
  /// **'ファイルアクセス権限の設定'**
  String get labelPermissionFileAccessTitle;

  /// No description provided for @labelPermissionFileAccessMessage.
  ///
  /// In ja, this message translates to:
  /// **'本アプリでファイルをリネームするには、Androidシステムの設定で「すべてのファイルの管理」を許可する必要があります。\n\n次の画面で「ReNamery」を探して、スイッチをONにしてください。'**
  String get labelPermissionFileAccessMessage;

  /// No description provided for @labelPermissionFileAccessButton.
  ///
  /// In ja, this message translates to:
  /// **'設定画面へ進む'**
  String get labelPermissionFileAccessButton;

  /// No description provided for @labelLicenseAgreementTitle.
  ///
  /// In ja, this message translates to:
  /// **'ソフトウェア利用規約'**
  String get labelLicenseAgreementTitle;

  /// No description provided for @labelLicenseAgreementMessage.
  ///
  /// In ja, this message translates to:
  /// **'本ソフトウェアを利用するには、以下のライセンス条項に同意する必要があります。'**
  String get labelLicenseAgreementMessage;

  /// No description provided for @labelLicenseDeclineExit.
  ///
  /// In ja, this message translates to:
  /// **'同意しない（アプリを終了する）'**
  String get labelLicenseDeclineExit;

  /// No description provided for @labelLicenseAcceptStart.
  ///
  /// In ja, this message translates to:
  /// **'同意して利用を開始する'**
  String get labelLicenseAcceptStart;

  /// No description provided for @labelAppTitle.
  ///
  /// In ja, this message translates to:
  /// **'ReNamery - ファイル名を安全に一括変更 | 東洋クラフト'**
  String get labelAppTitle;

  /// No description provided for @labelUpdateAvailable.
  ///
  /// In ja, this message translates to:
  /// **'新しいバージョン (v{version}) が利用可能です'**
  String labelUpdateAvailable(String version);

  /// No description provided for @labelViewSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定を見る'**
  String get labelViewSettings;

  /// No description provided for @labelLanguagePromptMessage.
  ///
  /// In ja, this message translates to:
  /// **'表示言語はアプリ設定で変更できます。'**
  String get labelLanguagePromptMessage;

  /// No description provided for @labelLanguagePromptAction.
  ///
  /// In ja, this message translates to:
  /// **'言語設定'**
  String get labelLanguagePromptAction;

  /// No description provided for @labelRecommendedLanguagePageMessage.
  ///
  /// In ja, this message translates to:
  /// **'ブラウザーの言語に合う{language}ページがあります: {url}'**
  String labelRecommendedLanguagePageMessage(String language, String url);

  /// No description provided for @labelRecommendedLanguagePageAction.
  ///
  /// In ja, this message translates to:
  /// **'開く'**
  String get labelRecommendedLanguagePageAction;

  /// No description provided for @labelAppExitTitle.
  ///
  /// In ja, this message translates to:
  /// **'アプリの終了'**
  String get labelAppExitTitle;

  /// No description provided for @labelAppExitConfirm.
  ///
  /// In ja, this message translates to:
  /// **'ReNamery を終了しますか？'**
  String get labelAppExitConfirm;

  /// No description provided for @labelExit.
  ///
  /// In ja, this message translates to:
  /// **'終了する'**
  String get labelExit;

  /// No description provided for @labelSkipInvalidTitle.
  ///
  /// In ja, this message translates to:
  /// **'エラーを含むファイルのスキップ確認'**
  String get labelSkipInvalidTitle;

  /// No description provided for @labelSkipInvalidMessage.
  ///
  /// In ja, this message translates to:
  /// **'選択されたファイルの中に、ファイル名が不正（禁止文字・重複など）なものが {invalidCount} 件あります。\n\nこれらを除外し、正常な {validCount} 件のファイルのみリネームを実行しますか？'**
  String labelSkipInvalidMessage(int invalidCount, int validCount);

  /// No description provided for @labelSkipAndContinue.
  ///
  /// In ja, this message translates to:
  /// **'スキップして続行'**
  String get labelSkipAndContinue;

  /// No description provided for @labelMsgExecutedWithSkipped.
  ///
  /// In ja, this message translates to:
  /// **'{executedCount} 件成功、{invalidCount} 件はエラーのためスキップされました'**
  String labelMsgExecutedWithSkipped(int executedCount, int invalidCount);

  /// No description provided for @labelMsgNoExecutableFiles.
  ///
  /// In ja, this message translates to:
  /// **'実行できるファイルがありませんでした'**
  String get labelMsgNoExecutableFiles;

  /// No description provided for @labelWebSelectFolderPromptTitle.
  ///
  /// In ja, this message translates to:
  /// **'ローカルフォルダを選択して開始'**
  String get labelWebSelectFolderPromptTitle;

  /// No description provided for @labelWebSelectFolderPromptMessage.
  ///
  /// In ja, this message translates to:
  /// **'Chrome系ブラウザで、選択したフォルダ内のファイル名をまとめて変更できます。'**
  String get labelWebSelectFolderPromptMessage;

  /// No description provided for @labelWebSelectFolderPromptPrivacy.
  ///
  /// In ja, this message translates to:
  /// **'データはデバイス以外に持ち出されることはありません。'**
  String get labelWebSelectFolderPromptPrivacy;

  /// No description provided for @labelWebSelectFolderPromptDesktopBeforeLink.
  ///
  /// In ja, this message translates to:
  /// **'シームレスな操作には、'**
  String get labelWebSelectFolderPromptDesktopBeforeLink;

  /// No description provided for @labelDesktopAppVersionLink.
  ///
  /// In ja, this message translates to:
  /// **'デスクトップ・アプリ版'**
  String get labelDesktopAppVersionLink;

  /// No description provided for @labelWebSelectFolderPromptDesktopAfterLink.
  ///
  /// In ja, this message translates to:
  /// **'をお勧めします。'**
  String get labelWebSelectFolderPromptDesktopAfterLink;

  /// No description provided for @labelWebUnsupportedPromptTitle.
  ///
  /// In ja, this message translates to:
  /// **'このブラウザでは利用できません'**
  String get labelWebUnsupportedPromptTitle;

  /// No description provided for @labelWebUnsupportedPromptMessage.
  ///
  /// In ja, this message translates to:
  /// **'ChromeまたはEdgeなどの対応ブラウザでお試しください。'**
  String get labelWebUnsupportedPromptMessage;

  /// No description provided for @labelSelectFolder.
  ///
  /// In ja, this message translates to:
  /// **'フォルダを選択'**
  String get labelSelectFolder;

  /// No description provided for @labelLicenseCannotExitTitle.
  ///
  /// In ja, this message translates to:
  /// **'アプリを終了できません'**
  String get labelLicenseCannotExitTitle;

  /// No description provided for @labelLicenseCannotExitMessage.
  ///
  /// In ja, this message translates to:
  /// **'ブラウザではアプリ側からタブを閉じられません。利用しない場合は、このタブを閉じてください。'**
  String get labelLicenseCannotExitMessage;

  /// No description provided for @labelDropOneFolder.
  ///
  /// In ja, this message translates to:
  /// **'フォルダを1つだけドロップしてください。'**
  String get labelDropOneFolder;

  /// No description provided for @labelDropFolderNotFile.
  ///
  /// In ja, this message translates to:
  /// **'ファイルではなくフォルダを1つだけドロップしてください。'**
  String get labelDropFolderNotFile;

  /// No description provided for @labelDropUnsupported.
  ///
  /// In ja, this message translates to:
  /// **'この環境ではフォルダのドラッグ&ドロップに対応していません。'**
  String get labelDropUnsupported;

  /// No description provided for @labelDropOpenFailed.
  ///
  /// In ja, this message translates to:
  /// **'フォルダを開けませんでした。'**
  String get labelDropOpenFailed;

  /// No description provided for @labelDropHereToOpen.
  ///
  /// In ja, this message translates to:
  /// **'ここにフォルダをドロップして開く'**
  String get labelDropHereToOpen;

  /// No description provided for @labelFileNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ファイルが存在しません'**
  String get labelFileNotFound;

  /// No description provided for @labelWindowsPropertiesFailed.
  ///
  /// In ja, this message translates to:
  /// **'Windowsプロパティ画面を開けませんでした'**
  String get labelWindowsPropertiesFailed;

  /// No description provided for @labelPropertiesTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロパティ: {name}'**
  String labelPropertiesTitle(String name);

  /// No description provided for @labelPropertyKind.
  ///
  /// In ja, this message translates to:
  /// **'種類'**
  String get labelPropertyKind;

  /// No description provided for @labelPropertyFileFolder.
  ///
  /// In ja, this message translates to:
  /// **'ファイル フォルダ'**
  String get labelPropertyFileFolder;

  /// No description provided for @labelPropertyFile.
  ///
  /// In ja, this message translates to:
  /// **'ファイル'**
  String get labelPropertyFile;

  /// No description provided for @labelPropertyLocation.
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get labelPropertyLocation;

  /// No description provided for @labelPropertySize.
  ///
  /// In ja, this message translates to:
  /// **'サイズ'**
  String get labelPropertySize;

  /// No description provided for @labelPropertyModified.
  ///
  /// In ja, this message translates to:
  /// **'更新日時'**
  String get labelPropertyModified;

  /// No description provided for @labelPropertyAttributes.
  ///
  /// In ja, this message translates to:
  /// **'属性'**
  String get labelPropertyAttributes;

  /// No description provided for @labelWebUnsupportedBrowserMessage.
  ///
  /// In ja, this message translates to:
  /// **'このブラウザでは、ローカルフォルダ連携に必要な機能が利用できません。ChromeまたはEdgeなど、対応しているPC向けブラウザでお試しください。'**
  String get labelWebUnsupportedBrowserMessage;

  /// No description provided for @labelWebLocalFolderPickerTitle.
  ///
  /// In ja, this message translates to:
  /// **'ローカルフォルダを選択'**
  String get labelWebLocalFolderPickerTitle;

  /// No description provided for @labelWebLocalFolderPickerSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'Chrome / Edge などの対応ブラウザで利用できます'**
  String get labelWebLocalFolderPickerSubtitle;

  /// No description provided for @labelWebNoSavedDirectories.
  ///
  /// In ja, this message translates to:
  /// **'選択済みフォルダはまだありません。'**
  String get labelWebNoSavedDirectories;

  /// No description provided for @labelWebDirectoryPermissionDenied.
  ///
  /// In ja, this message translates to:
  /// **'フォルダへのアクセスが許可されませんでした。'**
  String get labelWebDirectoryPermissionDenied;

  /// No description provided for @labelWebAccessUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'フォルダまたはファイルを読み込めませんでした。移動、削除、同期中などにより一部の項目へアクセスできない可能性があります。'**
  String get labelWebAccessUnavailable;

  /// No description provided for @labelWebNameRequired.
  ///
  /// In ja, this message translates to:
  /// **'ファイル名を入力してください。'**
  String get labelWebNameRequired;

  /// No description provided for @labelWebInvalidFileNameChars.
  ///
  /// In ja, this message translates to:
  /// **'ファイル名に使用できない文字が含まれています: / \\ : * ? \" < > |'**
  String get labelWebInvalidFileNameChars;

  /// No description provided for @labelWebDuplicateItem.
  ///
  /// In ja, this message translates to:
  /// **'同じ名前の項目が既にあります。'**
  String get labelWebDuplicateItem;

  /// No description provided for @labelWebDuplicateFile.
  ///
  /// In ja, this message translates to:
  /// **'同じ名前のファイルが既にあります。'**
  String get labelWebDuplicateFile;

  /// No description provided for @labelWebItemAccessLost.
  ///
  /// In ja, this message translates to:
  /// **'項目へのアクセス情報が失われています。フォルダを選択し直してください。'**
  String get labelWebItemAccessLost;

  /// No description provided for @labelWebFileAccessLost.
  ///
  /// In ja, this message translates to:
  /// **'ファイルへのアクセス情報が失われています。フォルダを選択し直してください。'**
  String get labelWebFileAccessLost;

  /// No description provided for @labelForgetQuickAccessTitle.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクセスから解除しますか？'**
  String get labelForgetQuickAccessTitle;

  /// No description provided for @labelForgetQuickAccessMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」をReNameryのクイックアクセスから解除します。\n\nフォルダやファイル自体は削除されません。\n再度利用する場合は「ローカルフォルダを選択」から追加してください。'**
  String labelForgetQuickAccessMessage(String name);

  /// No description provided for @labelForget.
  ///
  /// In ja, this message translates to:
  /// **'解除'**
  String get labelForget;

  /// No description provided for @labelForgetQuickAccessAction.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクセスから解除'**
  String get labelForgetQuickAccessAction;

  /// No description provided for @labelForgetQuickAccessSuccess.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクセスから解除しました。ファイルは削除されていません。'**
  String get labelForgetQuickAccessSuccess;

  /// No description provided for @labelForgetQuickAccessFailure.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクセスから解除できませんでした。'**
  String get labelForgetQuickAccessFailure;

  /// No description provided for @labelArchiveContents.
  ///
  /// In ja, this message translates to:
  /// **'アーカイブ内容:'**
  String get labelArchiveContents;

  /// No description provided for @labelPreviewError.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {message}'**
  String labelPreviewError(String message);

  /// No description provided for @labelPreviewUnsupportedWeb.
  ///
  /// In ja, this message translates to:
  /// **'Web版では{target}の内容プレビューは未対応です。\nファイル名、種類、サイズなどの情報は一覧で確認できます。'**
  String labelPreviewUnsupportedWeb(String target);

  /// No description provided for @labelPreviewTargetThisFile.
  ///
  /// In ja, this message translates to:
  /// **'このファイル'**
  String get labelPreviewTargetThisFile;

  /// No description provided for @labelPreviewTargetExtensionFile.
  ///
  /// In ja, this message translates to:
  /// **'{extension}ファイル'**
  String labelPreviewTargetExtensionFile(String extension);

  /// No description provided for @labelScanConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'スキャンの確認'**
  String get labelScanConfirmTitle;

  /// No description provided for @labelScanConfirmCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 件のファイルが見つかりました。\nスキャンを続行しますか？'**
  String labelScanConfirmCount(int count);

  /// No description provided for @labelScanConfirmTime.
  ///
  /// In ja, this message translates to:
  /// **'スキャン開始から5秒が経過しました（現在 {count} 件）。\nこのまま続行しますか？'**
  String labelScanConfirmTime(int count);

  /// No description provided for @labelScanConfirmStall.
  ///
  /// In ja, this message translates to:
  /// **'応答が一時的に途絶えています。スキャンを続行しますか？'**
  String get labelScanConfirmStall;

  /// No description provided for @labelScanCancelClear.
  ///
  /// In ja, this message translates to:
  /// **'中止 (クリア)'**
  String get labelScanCancelClear;

  /// No description provided for @labelScanStopAndShow.
  ///
  /// In ja, this message translates to:
  /// **'ここで止めて表示'**
  String get labelScanStopAndShow;

  /// No description provided for @labelScanContinue.
  ///
  /// In ja, this message translates to:
  /// **'続行する'**
  String get labelScanContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'ja':
      {
        switch (locale.countryCode) {
          case 'NM':
            return AppLocalizationsJaNm();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
