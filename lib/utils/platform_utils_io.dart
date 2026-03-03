import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:win32/win32.dart';
import '../core/file_model.dart';
import 'platform_utils_stub.dart';

const int SEE_MASK_INVOKEIDLIST = 0x0000000C;

void showPropertiesDialogImpl(BuildContext context, FileModel fileModel) {
  final path = fileModel.entity.path;

  if (Platform.isWindows) {
    if (!File(path).existsSync() && !Directory(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルが存在しません')),
      );
      return;
    }

    final pPath = path.toNativeUtf16();
    final pVerb = 'properties'.toNativeUtf16();
    final sei = pkg_ffi.calloc<SHELLEXECUTEINFO>()
      ..ref.cbSize = ffi.sizeOf<SHELLEXECUTEINFO>()
      ..ref.fMask = SEE_MASK_INVOKEIDLIST
      ..ref.hwnd = NULL
      ..ref.lpVerb = pVerb
      ..ref.lpFile = pPath
      ..ref.lpParameters = ffi.nullptr
      ..ref.lpDirectory = ffi.nullptr
      ..ref.nShow = SW_SHOW
      ..ref.hInstApp = NULL;

    final result = ShellExecuteEx(sei);

    pkg_ffi.calloc.free(pPath);
    pkg_ffi.calloc.free(pVerb);
    pkg_ffi.calloc.free(sei);

    if (result == FALSE) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Windowsプロパティ画面を開けませんでした')),
        );
      }
    }
  } else if (Platform.isMacOS) {
    Process.run('osascript', [
      '-e',
      'tell application "Finder" to open information window of (POSIX file "$path" as alias)'
    ]).then((result) {
      if (result.exitCode != 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Macプロパティ画面を開けませんでした: ${result.stderr}')),
        );
      }
    });
  } else {
    showCustomPropertiesDialog(context, fileModel);
  }
}
