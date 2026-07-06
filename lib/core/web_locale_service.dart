import 'web_locale_service_stub.dart'
    if (dart.library.js_interop) 'web_locale_service_js.dart' as implementation;

String? readPageInitialLocale() => implementation.readPageInitialLocale();

List<String> readPreferredLocaleTags() =>
    implementation.readPreferredLocaleTags();
