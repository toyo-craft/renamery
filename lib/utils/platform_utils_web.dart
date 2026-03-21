import 'package:flutter/material.dart';
import '../core/file_model.dart';
import 'platform_utils_stub.dart';

void showPropertiesDialogImpl(BuildContext context, FileModel fileModel) {
  showCustomPropertiesDialog(context, fileModel);
}

void openFileImpl(String path) {
  // Web does not support opening local files by path
}
