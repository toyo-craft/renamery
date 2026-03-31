#!/bin/bash

# Debian (.deb) パッケージ手動作成スクリプト
# ツール (flutter_to_debian) のバグを回避するため、直接構築します。

set -e

PKG_NAME="renamery"
# pubspec.yaml からバージョンを取得
VERSION=$(grep 'version: ' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1 | tr -d ' ')
ARCH="amd64"
MAINTAINER="toyo-craft <toyo-craft@example.com>"
DESC="ReNamery - A modern batch renaming utility."

echo "Cleaning and Building..."
flutter clean
flutter pub get
flutter build linux --release

echo "Preparing Debian staging area..."
STAGING="build/debian_staging"
rm -rf "$STAGING"
mkdir -p "$STAGING/DEBIAN"
mkdir -p "$STAGING/usr/lib/$PKG_NAME"
mkdir -p "$STAGING/usr/bin"
mkdir -p "$STAGING/usr/share/applications"
mkdir -p "$STAGING/usr/share/icons/hicolor/256x256/apps"

# 1. バイナリとアセットのコピー
cp -r build/linux/x64/release/bundle/* "$STAGING/usr/lib/$PKG_NAME/"

# 2. アイコンの配置
if [ -f "assets/icon/app_icon.png" ]; then
    cp assets/icon/app_icon.png "$STAGING/usr/share/icons/hicolor/256x256/apps/$PKG_NAME.png"
fi

# 3. デスクトップエントリの作成
cat <<EOT > "$STAGING/usr/share/applications/$PKG_NAME.desktop"
[Desktop Entry]
Version=$VERSION
Name=ReNamery
Comment=$DESC
Exec=/usr/bin/$PKG_NAME
Icon=$PKG_NAME
Terminal=false
Type=Application
Categories=Utility;
EOT

# 4. 実行用ラッパースクリプトの作成
cat <<EOT > "$STAGING/usr/bin/$PKG_NAME"
#!/bin/bash
cd /usr/lib/$PKG_NAME
exec ./renamery "\$@"
EOT
chmod +x "$STAGING/usr/bin/$PKG_NAME"
chmod +x "$STAGING/usr/lib/$PKG_NAME/renamery"

# 5. Control ファイルの作成（手動でクリーンに記述）
cat <<EOT > "$STAGING/DEBIAN/control"
Package: $PKG_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Description: $DESC
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, libblkid1, liblzma5, libgcrypt20, libsecret-1-0, libfontconfig1, libdbus-1-3
EOT

# 6. パッケージのビルド
echo "Building .deb package..."
mkdir -p build/debian
OUTPUT_FILENAME="ReNamery-v${VERSION}-linux-${ARCH}.deb"
dpkg-deb --build "$STAGING" "build/debian/$OUTPUT_FILENAME"

echo "--------------------------------------------------"
echo "Success! build/debian/$OUTPUT_FILENAME"
echo "--------------------------------------------------"
