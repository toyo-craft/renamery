import 'dart:convert';
import 'dart:io';

const _siteOrigin = 'https://renamery.toyo-craft.net';
const _iconUrl = '$_siteOrigin/icons/Icon-512.png';
const _githubUrl = 'https://github.com/toyo-craft/renamery';
const _releasesUrl = '$_githubUrl/releases';
const _licenseUrl = '$_githubUrl/blob/main/LICENSE';
const _appsUrl = 'https://toyo-craft.net/apps';
const _authorName = 'TOYO CRAFT Laboratory&Co.';
const _authorUrl = 'https://toyo-craft.net/';

const _metaStart = '<!-- RENAMERY_META_START -->';
const _metaEnd = '<!-- RENAMERY_META_END -->';
const _seoStart = '<!-- RENAMERY_SEO_CONTENT_START -->';
const _seoEnd = '<!-- RENAMERY_SEO_CONTENT_END -->';

void main() {
  final buildDir = Directory('build/web');
  final indexFile = File('${buildDir.path}/index.html');
  if (!indexFile.existsSync()) {
    stderr.writeln(
        'build/web/index.html was not found. Run flutter build web first.');
    exitCode = 1;
    return;
  }

  final source = indexFile.readAsStringSync();
  final version = _readVersion();
  final pages = _pages(version);
  final rootPage = pages.firstWhere((page) => page.code == 'x-default');

  indexFile.writeAsStringSync(_renderPage(source, rootPage));

  for (final page in pages.where((page) => page.code != 'x-default')) {
    final directory = Directory('${buildDir.path}/${page.path}');
    directory.createSync(recursive: true);
    File('${directory.path}/index.html')
        .writeAsStringSync(_renderPage(source, page));
  }

  for (final page in pages) {
    final manifestName = page.manifestName;
    File('${buildDir.path}/$manifestName').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(_manifestFor(page)),
    );
  }

  File('${buildDir.path}/robots.txt').writeAsStringSync(_robotsTxt());
  File('${buildDir.path}/sitemap.xml').writeAsStringSync(_sitemapXml());
}

String _readVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match =
      RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(pubspec);
  return match?.group(1) ?? '0.0.0';
}

String _renderPage(String source, WebLocalePage page) {
  var output = source.replaceFirst(
    RegExp(r'<html lang="[^"]*">'),
    '<html lang="${page.htmlLang}">',
  );
  output = _replaceMarkedBlock(output, _metaStart, _metaEnd, _metaBlock(page));
  output = _replaceMarkedBlock(output, _seoStart, _seoEnd, _seoContent(page));
  return output;
}

String _replaceMarkedBlock(
    String source, String start, String end, String replacement) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end);
  if (startIndex < 0 || endIndex < 0 || endIndex < startIndex) {
    throw StateError('Could not find marker block: $start / $end');
  }
  final endClose = endIndex + end.length;
  return '${source.substring(0, startIndex)}$start\n$replacement\n  $end${source.substring(endClose)}';
}

String _metaBlock(WebLocalePage page) {
  final alternates = _alternateLinks();
  final alternateOg = _ogAlternateLocales(page);
  final jsonLd = const JsonEncoder.withIndent('    ').convert(_jsonLdFor(page));

  return '''  <meta name="description" content="${_attr(page.description)}">
  <meta name="application-name" content="ReNamery">
  <meta name="author" content="${_attr(_authorName)}">
  <meta name="creator" content="${_attr(_authorName)}">
  <meta name="publisher" content="${_attr(_authorName)}">
  <meta name="keywords" content="${_attr(page.keywords)}">
  <meta name="theme-color" content="#2E7D32">
  <meta name="color-scheme" content="light">
  <link rel="canonical" href="${_attr(page.url)}">
$alternates

  <meta property="og:site_name" content="ReNamery">
  <meta property="og:title" content="${_attr(page.title)}">
  <meta property="og:description" content="${_attr(page.ogDescription)}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${_attr(page.url)}">
  <meta property="og:image" content="$_iconUrl">
  <meta property="og:image:width" content="512">
  <meta property="og:image:height" content="512">
  <meta property="og:locale" content="${page.ogLocale}">
$alternateOg

  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="${_attr(page.title)}">
  <meta name="twitter:description" content="${_attr(page.twitterDescription)}">
  <meta name="twitter:image" content="$_iconUrl">
  <title>${_html(page.title)}</title>
  <link rel="manifest" href="${page.manifestName}">
  <script id="renamery-locale-bootstrap">
    window.renameryInitialLocale = '${page.initialLocale}';
    window.renameryPageLocale = '${page.code}';
    window.renameryLocale = {
      initialLocale: window.renameryInitialLocale,
      pageLocale: window.renameryPageLocale,
      getInitialLocale: () => window.renameryInitialLocale,
      preferredLocales: () => Array.from(
        navigator.languages && navigator.languages.length
          ? navigator.languages
          : [navigator.language]
      ).filter(Boolean),
      getPreferredLocales: () => Array.from(
        navigator.languages && navigator.languages.length
          ? navigator.languages
          : [navigator.language]
      ).filter(Boolean),
    };
  </script>
  <script type="application/ld+json">
$jsonLd
  </script>''';
}

String _alternateLinks() {
  final links = <String>[
    '  <link rel="alternate" hreflang="ja" href="$_siteOrigin/ja/">',
    '  <link rel="alternate" hreflang="en" href="$_siteOrigin/en/">',
    '  <link rel="alternate" hreflang="es" href="$_siteOrigin/es/">',
    '  <link rel="alternate" hreflang="zh-Hans" href="$_siteOrigin/zh/">',
    '  <link rel="alternate" hreflang="x-default" href="$_siteOrigin/">',
  ];
  return links.join('\n');
}

String _ogAlternateLocales(WebLocalePage current) {
  const all = <String>['ja_JP', 'en_US', 'es_ES', 'zh_CN'];
  return all
      .where((locale) => locale != current.ogLocale)
      .map((locale) =>
          '  <meta property="og:locale:alternate" content="$locale">')
      .join('\n');
}

String _seoContent(WebLocalePage page) {
  final featureItems = page.features
      .map((feature) => '      <li>${_html(feature)}</li>')
      .join('\n');
  final faqItems =
      page.faq.map((item) => '''      <dt>${_html(item.question)}</dt>
      <dd>${_html(item.answer)}</dd>''').join('\n');

  return '''  <main id="renamery-seo-content" class="renamery-seo-content">
    <h1>${_html(page.heading)}</h1>
    <p>${_html(page.summary)}</p>
    <p>${_html(page.context)}</p>
    <h2>${_html(page.featuresHeading)}</h2>
    <ul>
$featureItems
    </ul>
    <h2>${_html(page.faqHeading)}</h2>
    <dl>
$faqItems
    </dl>
    <p><a href="$_releasesUrl">${_html(page.downloadLabel)}</a> / <a href="$_githubUrl">${_html(page.sourceLabel)}</a></p>
  </main>
  <script>
    window.addEventListener('flutter-first-frame', () => {
      document.getElementById('renamery-seo-content')?.remove();
    });
  </script>''';
}

Map<String, Object?> _jsonLdFor(WebLocalePage page) => {
      '@context': 'https://schema.org',
      '@type': ['WebApplication', 'SoftwareApplication'],
      'name': 'ReNamery',
      'alternateName': page.alternateNames,
      'applicationCategory': 'UtilitiesApplication',
      'operatingSystem': 'Windows, Android, Linux, Web',
      'url': page.url,
      'inLanguage': page.htmlLang,
      'description': page.description,
      'image': _iconUrl,
      'screenshot': const [
        'https://toyo-craft.net/images/cap_renamery01.png',
        'https://toyo-craft.net/images/cap_renamery02.png',
        'https://toyo-craft.net/images/cap_renamery03.png',
        'https://toyo-craft.net/images/cap_renamery04.png',
      ],
      'softwareVersion': page.version,
      'isAccessibleForFree': true,
      'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'USD'},
      'featureList': page.features,
      'license': _licenseUrl,
      'codeRepository': _githubUrl,
      'downloadUrl': _releasesUrl,
      'author': {
        '@type': 'Organization',
        'name': _authorName,
        'url': _authorUrl
      },
      'publisher': {
        '@type': 'Organization',
        'name': _authorName,
        'url': _authorUrl
      },
      'sameAs': const [_appsUrl, _githubUrl],
      'subjectOf': const [
        {
          '@type': 'WebPage',
          'name': 'ReNamery on Vector',
          'url': 'https://www.vector.co.jp/soft/winnt/util/se528679.html',
        },
        {
          '@type': 'NewsArticle',
          'name': 'ReNamery in Mado no Mori Digest News',
          'url': 'https://forest.watch.impress.co.jp/docs/digest/2099794.html',
        },
      ],
      'mainEntity': page.faq
          .map((item) => {
                '@type': 'Question',
                'name': item.question,
                'acceptedAnswer': {'@type': 'Answer', 'text': item.answer},
              })
          .toList(),
    };

Map<String, Object?> _manifestFor(WebLocalePage page) => {
      'name': 'ReNamery',
      'short_name': 'ReNamery',
      'id': page.url,
      'start_url': page.code == 'x-default' ? '.' : './${page.path}/',
      'scope': '/',
      'display': 'standalone',
      'background_color': '#F7FBF4',
      'theme_color': '#2E7D32',
      'description': page.description,
      'lang': page.htmlLang,
      'categories': ['productivity', 'utilities'],
      'orientation': 'any',
      'prefer_related_applications': false,
      'icons': const [
        {'src': 'icons/Icon-192.png', 'sizes': '192x192', 'type': 'image/png'},
        {'src': 'icons/Icon-512.png', 'sizes': '512x512', 'type': 'image/png'},
        {
          'src': 'icons/Icon-maskable-192.png',
          'sizes': '192x192',
          'type': 'image/png',
          'purpose': 'maskable'
        },
        {
          'src': 'icons/Icon-maskable-512.png',
          'sizes': '512x512',
          'type': 'image/png',
          'purpose': 'maskable'
        },
      ],
    };

String _robotsTxt() => '''User-agent: *
Allow: /

Sitemap: $_siteOrigin/sitemap.xml
''';

String _sitemapXml() {
  final locs = <String>[
    '$_siteOrigin/',
    '$_siteOrigin/ja/',
    '$_siteOrigin/en/',
    '$_siteOrigin/es/',
    '$_siteOrigin/zh/',
  ];
  const alternates =
      '''    <xhtml:link rel="alternate" hreflang="ja" href="$_siteOrigin/ja/" />
    <xhtml:link rel="alternate" hreflang="en" href="$_siteOrigin/en/" />
    <xhtml:link rel="alternate" hreflang="es" href="$_siteOrigin/es/" />
    <xhtml:link rel="alternate" hreflang="zh-Hans" href="$_siteOrigin/zh/" />
    <xhtml:link rel="alternate" hreflang="x-default" href="$_siteOrigin/" />''';
  final urls = locs.map((url) => '''  <url>
    <loc>${_xml(url)}</loc>
$alternates
  </url>''').join('\n');
  return '''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
$urls
</urlset>
''';
}

String _attr(String value) =>
    const HtmlEscape(HtmlEscapeMode.attribute).convert(value);
String _html(String value) => const HtmlEscape().convert(value);
String _xml(String value) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(value);

List<WebLocalePage> _pages(String version) => [
      _englishPage(version,
          code: 'x-default',
          path: '',
          initialLocale: 'auto',
          url: '$_siteOrigin/'),
      _englishPage(version,
          code: 'en', path: 'en', initialLocale: 'en', url: '$_siteOrigin/en/'),
      WebLocalePage(
        version: version,
        code: 'ja',
        path: 'ja',
        initialLocale: 'ja',
        htmlLang: 'ja',
        ogLocale: 'ja_JP',
        url: '$_siteOrigin/ja/',
        manifestName: 'manifest-ja.json',
        title: 'ReNamery | 安全にプレビューできる一括ファイル名変更ツール',
        description:
            'ReNameryは、先行する優れたリネームツールの開拓者たちが築いた思想と直感的な操作感への敬意を受け継ぎ、現代の環境に合わせて再編成した一括ファイル名変更ツールです。3ペインUIで変更後の名前を確認しながら、連番、正規表現置換、拡張子変更、Undo、画像/PDF/SVG/ZIPプレビューを利用できます。',
        ogDescription:
            '先行するリネームツールの開拓者たちが築いた思想と操作感への敬意を受け継ぎ、現代の環境に合わせて再編成した一括ファイル名変更ツールです。',
        twitterDescription:
            '変更後の名前を確認しながら、連番、正規表現置換、拡張子変更、Undo、画像/PDF/SVG/ZIPプレビューを使える一括リネームツールです。',
        keywords:
            'ReNamery,リネームリー,ファイル名変更,一括リネーム,リネームソフト,連番,正規表現,拡張子変更,東洋クラフト',
        alternateNames: const ['リネームリー', 'リネーム思想継承ツール'],
        heading: 'ReNamery - 安全にプレビューできる一括ファイル名変更ツール',
        summary:
            'ReNameryは、先行するリネームツールの開拓者が示した思想と操作感への敬意を出発点に、現代の利用環境へ合わせて再編成した一括ファイル名変更ツールです。変更後の名前を実行前に確認しながら、連番、正規表現置換、拡張子変更、Undo、画像/PDF/SVG/ZIPプレビューを利用できます。',
        context:
            'Windows、Android、Linux、Webで利用できる進化プロトタイプとして、東洋クラフト labが開発しています。WEB版はブラウザで素早く試せ、実運用にはGitHub Releasesから各OS版をダウンロードできます。',
        featuresHeading: '主な機能',
        faqHeading: 'よくある質問',
        downloadLabel: '最新版をダウンロード',
        sourceLabel: 'ソースコードを見る',
        features: const [
          'フォルダツリー、ファイル一覧、リネーム設定を一画面で扱える3ペインUI',
          '実行前に変更後のファイル名を確認できるリアルタイムプレビュー',
          '連番、文字列追加/削除、正規表現置換、拡張子変更に対応',
          'リネーム後でも元の名前へ戻せるUndo',
          '画像、PDF、SVG、ZIP内容のプレビュー',
        ],
        faq: const [
          FaqItem('ReNameryは何をするアプリですか？',
              '複数のファイル名を、実行前のプレビューを確認しながら一括変更するためのリネーム支援アプリです。'),
          FaqItem('WEB版でローカルファイルはアップロードされますか？',
              'ブラウザのFile System Access APIを使い、選択したフォルダを端末上で扱います。ファイルをサーバーへアップロードする設計ではありません。'),
          FaqItem('どの環境で使えますか？',
              'Windows、Android、Linux、Webで利用できます。Windows版は属性やタイムスタンプ変更にも対応しています。'),
        ],
      ),
      WebLocalePage(
        version: version,
        code: 'es',
        path: 'es',
        initialLocale: 'es',
        htmlLang: 'es',
        ogLocale: 'es_ES',
        url: '$_siteOrigin/es/',
        manifestName: 'manifest-es.json',
        title: 'ReNamery | Renombrador por lotes con vista previa segura',
        description:
            'ReNamery es una herramienta moderna para renombrar archivos por lotes inspirada en Namery. Permite previsualizar cambios, usar numeración, expresiones regulares, cambios de extensión, deshacer y vistas previas de imagen/PDF/SVG/ZIP.',
        ogDescription:
            'Renombra archivos por lotes con vista previa, numeración, expresiones regulares, cambios de extensión, deshacer y vistas previas de imagen/PDF/SVG/ZIP.',
        twitterDescription:
            'Previsualiza y renombra archivos por lotes con numeración, expresiones regulares, cambios de extensión, deshacer y vistas previas de archivos.',
        keywords:
            'ReNamery, renombrar archivos, renombrador por lotes, Namery, expresiones regulares, numeracion, utilidad de archivos, Toyo Craft',
        alternateNames: const ['Renombrador inspirado en Namery'],
        heading: 'ReNamery - Renombrador por lotes con vista previa segura',
        summary:
            'ReNamery es un renombrador moderno inspirado en Namery. Permite comprobar los nombres nuevos antes de ejecutar los cambios y ofrece numeración, reemplazo con expresiones regulares, cambios de extensión, deshacer y vista previa de imágenes, PDF, SVG y ZIP.',
        context:
            'El proyecto es un prototipo evolutivo de TOYO CRAFT Laboratory&Co. para Windows, Android, Linux y Web. Puede probar la versión Web o descargar las versiones de escritorio y móvil desde GitHub Releases.',
        featuresHeading: 'Funciones principales',
        faqHeading: 'Preguntas frecuentes',
        downloadLabel: 'Descargar la versión más reciente',
        sourceLabel: 'Ver código fuente',
        features: const [
          'Interfaz de tres paneles para árbol de carpetas, lista de archivos y reglas de renombrado',
          'Vista previa en tiempo real antes de ejecutar los cambios',
          'Numeración, agregar/quitar texto, expresiones regulares y cambios de extensión',
          'Deshacer después de renombrar',
          'Vista previa de imágenes, PDF, SVG y contenido ZIP',
        ],
        faq: const [
          FaqItem('¿Para qué sirve ReNamery?',
              'Sirve para cambiar muchos nombres de archivo a la vez comprobando una vista previa antes de ejecutar la operación.'),
          FaqItem('¿La versión Web sube mis archivos?',
              'No está diseñada para subir archivos al servidor. Usa la File System Access API del navegador para trabajar con la carpeta seleccionada en el dispositivo.'),
          FaqItem('¿En qué plataformas funciona?',
              'Funciona en Windows, Android, Linux y Web. La versión de Windows incluye funciones adicionales como atributos y marcas de tiempo.'),
        ],
      ),
      WebLocalePage(
        version: version,
        code: 'zh',
        path: 'zh',
        initialLocale: 'zh',
        htmlLang: 'zh-Hans',
        ogLocale: 'zh_CN',
        url: '$_siteOrigin/zh/',
        manifestName: 'manifest-zh.json',
        title: 'ReNamery | 带实时预览的批量文件重命名工具',
        description:
            'ReNamery 是受 Namery 启发的现代批量文件重命名工具。通过三栏界面安全预览更名结果，支持编号、正则替换、扩展名修改、撤销以及图片/PDF/SVG/ZIP 预览。',
        ogDescription: '受 Namery 启发的批量重命名工具，支持实时预览、编号、正则替换、扩展名修改、撤销和文件内容预览。',
        twitterDescription:
            '通过实时预览安全批量重命名文件，支持编号、正则替换、扩展名修改、撤销以及图片/PDF/SVG/ZIP 预览。',
        keywords: 'ReNamery,批量重命名,文件重命名,Namery,正则替换,编号,扩展名修改,文件工具,Toyo Craft',
        alternateNames: const ['受 Namery 启发的批量重命名工具'],
        heading: 'ReNamery - 带实时预览的批量文件重命名工具',
        summary:
            'ReNamery 是一款受 Namery 启发的现代批量文件重命名工具。它可以在执行前预览新文件名，并支持编号、正则替换、扩展名修改、撤销以及图片、PDF、SVG、ZIP 内容预览。',
        context:
            '该项目由 TOYO CRAFT Laboratory&Co. 开发，是面向 Windows、Android、Linux 和 Web 的持续演进原型。您可以直接试用 Web 版，也可以从 GitHub Releases 下载各平台版本。',
        featuresHeading: '主要功能',
        faqHeading: '常见问题',
        downloadLabel: '下载最新版',
        sourceLabel: '查看源代码',
        features: const [
          '三栏界面：文件夹树、文件列表和重命名规则一屏呈现',
          '执行前实时预览新的文件名',
          '支持编号、添加/删除文本、正则替换和扩展名修改',
          '重命名后可撤销',
          '支持图片、PDF、SVG 和 ZIP 内容预览',
        ],
        faq: const [
          FaqItem('ReNamery 是做什么的？', '它用于在执行前确认预览结果，并批量修改多个文件的名称。'),
          FaqItem('Web 版会上传本地文件吗？',
              '设计上不会把文件上传到服务器。它使用浏览器的 File System Access API 在本机处理所选文件夹。'),
          FaqItem('支持哪些平台？',
              '支持 Windows、Android、Linux 和 Web。Windows 版还支持属性和时间戳修改等功能。'),
        ],
      ),
    ];

WebLocalePage _englishPage(
  String version, {
  required String code,
  required String path,
  required String initialLocale,
  required String url,
}) =>
    WebLocalePage(
      version: version,
      code: code,
      path: path,
      initialLocale: initialLocale,
      htmlLang: 'en',
      ogLocale: 'en_US',
      url: url,
      manifestName: code == 'x-default' ? 'manifest.json' : 'manifest-en.json',
      title: 'ReNamery | Safe Batch File Renamer with Live Preview',
      description:
          'ReNamery is a modern batch file renamer inspired by Namery. Preview changes in a 3-pane UI and use numbering, regex replacement, extension changes, undo, and image/PDF/SVG/ZIP previews on Windows, Android, Linux, and Web.',
      ogDescription:
          'A modern batch file renamer inspired by Namery, with live previews, numbering, regex replacement, extension changes, undo, and file content previews.',
      twitterDescription:
          'Preview and safely batch rename files with numbering, regex replacement, extension changes, undo, and image/PDF/SVG/ZIP previews.',
      keywords:
          'ReNamery, batch file renamer, rename files, bulk rename, Namery, regex rename, file utility, Toyo Craft',
      alternateNames: const ['Namery-inspired batch renamer', 'リネームリー'],
      heading: 'ReNamery - Safe Batch File Renamer with Live Preview',
      summary:
          'ReNamery is a modern batch file renamer inspired by Namery, the classic Windows renaming utility. It helps you preview file name changes before execution and supports numbering, regex replacement, extension changes, undo, and previews for images, PDFs, SVGs, and ZIP archives.',
      context:
          'Developed by TOYO CRAFT Laboratory&Co., ReNamery is an evolving prototype for practical file-management workflows across Windows, Android, Linux, and Web. Try it in the browser or download native releases from GitHub.',
      featuresHeading: 'Key features',
      faqHeading: 'Frequently asked questions',
      downloadLabel: 'Download the latest release',
      sourceLabel: 'View source code',
      features: const [
        '3-pane interface for folder tree, file list, and rename rules',
        'Live preview before applying file name changes',
        'Numbering, add/remove text, regex replacement, and extension changes',
        'Undo after renaming',
        'Preview images, PDFs, SVGs, and ZIP contents',
      ],
      faq: const [
        FaqItem('What does ReNamery do?',
            'ReNamery helps you batch rename many files while checking the preview before execution.'),
        FaqItem('Does the Web version upload local files?',
            'No. It uses the browser File System Access API to work with the selected folder on your device and is not designed to upload files to a server.'),
        FaqItem('Which platforms are supported?',
            'ReNamery supports Windows, Android, Linux, and Web. The Windows version also supports file attributes and timestamp changes.'),
      ],
    );

class WebLocalePage {
  const WebLocalePage({
    required this.version,
    required this.code,
    required this.path,
    required this.initialLocale,
    required this.htmlLang,
    required this.ogLocale,
    required this.url,
    required this.manifestName,
    required this.title,
    required this.description,
    required this.ogDescription,
    required this.twitterDescription,
    required this.keywords,
    required this.alternateNames,
    required this.heading,
    required this.summary,
    required this.context,
    required this.featuresHeading,
    required this.faqHeading,
    required this.downloadLabel,
    required this.sourceLabel,
    required this.features,
    required this.faq,
  });

  final String version;
  final String code;
  final String path;
  final String initialLocale;
  final String htmlLang;
  final String ogLocale;
  final String url;
  final String manifestName;
  final String title;
  final String description;
  final String ogDescription;
  final String twitterDescription;
  final String keywords;
  final List<String> alternateNames;
  final String heading;
  final String summary;
  final String context;
  final String featuresHeading;
  final String faqHeading;
  final String downloadLabel;
  final String sourceLabel;
  final List<String> features;
  final List<FaqItem> faq;
}

class FaqItem {
  const FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}
