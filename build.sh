#!/bin/bash
# Coreio 打包脚本：无签名构建 + 打包成 ipa
# 用法：./build.sh           # 生成未签名 ipa（TrollStore 直接装）
#      ./build.sh --sign    # 额外用 ldid 打上越狱权限（需要已安装 ldid）
set -e

cd "$(dirname "$0")"

BUILD_DIR="build"
IPA_NAME="Coreio.ipa"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> 编译 Release（不签名）"
xcodebuild \
  -project Coreio.xcodeproj \
  -target Coreio \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="$BUILD_DIR/Release/Coreio.app"
[ -d "$APP_PATH" ] || { echo "编译产物不存在：$APP_PATH"; exit 1; }

if [ "$1" == "--sign" ]; then
  if command -v ldid >/dev/null 2>&1; then
    echo "==> ldid 签名 + 越狱权限"
    ldid -S"Coreio.entitlements" "$APP_PATH/Coreio"
  else
    echo "!! 没装 ldid，跳过签名（TrollStore 装的时候会自动签）"
  fi
fi

echo "==> 打包 ipa"
rm -rf "$BUILD_DIR/Payload"
mkdir -p "$BUILD_DIR/Payload"
cp -R "$APP_PATH" "$BUILD_DIR/Payload/"
cd "$BUILD_DIR"
rm -f "$IPA_NAME"
zip -qr "$IPA_NAME" Payload
cd ..

echo "==> 完成：$(pwd)/$BUILD_DIR/$IPA_NAME"
