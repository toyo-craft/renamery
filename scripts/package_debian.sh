#!/bin/bash

# Debian (.deb) パッケージ作成スクリプト
# Linux環境またはWSL上で実行してください。

set -e

echo "Cleaning build directory..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building Linux release..."
flutter build linux --release

echo "Creating Debian package..."
flutter pub run flutter_to_debian

echo "--------------------------------------------------"
echo "Done! The .deb package should be in build/debian/"
echo "--------------------------------------------------"
