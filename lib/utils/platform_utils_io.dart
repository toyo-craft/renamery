import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:win32/win32.dart';
import '../core/file_model.dart';

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
    // ...
  }
}

void openFileImpl(String path) {
  if (Platform.isWindows) {
    // Windows ではバックスラッシュを使用する方が確実
    final normalizedPath = path.replaceAll('/', '\\');
    final pPath = normalizedPath.toNativeUtf16();
    
    // lpOperation に nullptr を渡すと、デフォルトの動作（通常は 'open'）が実行される
    // これにより、関連付けられたアプリがより確実に起動する
    final result = ShellExecute(0, ffi.nullptr, pPath, ffi.nullptr, ffi.nullptr, SW_SHOWNORMAL);
    
    if (result <= 32) {
      // 失敗した場合は念のため 'open' を明示して再試行
      final pVerb = 'open'.toNativeUtf16();
      ShellExecute(0, pVerb, pPath, ffi.nullptr, ffi.nullptr, SW_SHOWNORMAL);
      pkg_ffi.calloc.free(pVerb);
    }
    
    pkg_ffi.calloc.free(pPath);
  } else if (Platform.isMacOS) {
    Process.run('open', [path]);
  } else {
    Process.run('xdg-open', [path]);
  }
}
