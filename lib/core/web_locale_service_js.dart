import 'dart:js_interop';

String? readPageInitialLocale() {
  try {
    return _bridgeGetInitialLocale()?.toDart.trim();
  } catch (_) {
    return null;
  }
}

List<String> readPreferredLocaleTags() {
  try {
    return _bridgeGetPreferredLocales()
        .toDart
        .map((tag) => tag.toDart)
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}

@JS('renameryLocale.getInitialLocale')
external JSString? _bridgeGetInitialLocale();

@JS('renameryLocale.getPreferredLocales')
external JSArray<JSString> _bridgeGetPreferredLocales();
