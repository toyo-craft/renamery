import 'package:flutter/material.dart';

import 'package:renamery/core/file_model.dart';

import 'platform_utils_stub.dart'
    if (dart.library.html) 'platform_utils_web.dart'
    if (dart.library.io) 'platform_utils_io.dart';

abstract class PlatformUtils {
  static void showPropertiesDialog(BuildContext context, FileModel fileModel) {
    showPropertiesDialogImpl(context, fileModel);
  }

  static void openFile(String path) {
    openFileImpl(path);
  }
}
