#!/bin/bash
# Build an unsigned .ipa so it can be re-signed with Sideloadly / AltStore / TrollStore.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild 不可用。" >&2
  echo "请安装完整版 Xcode，然后执行： sudo xcode-select -s /Applications/Xcode.app" >&2
  exit 1
fi

echo "==> 编译 Release（不签名）"
xcodebuild \
  -project PayFlowDemo.xcodeproj \
  -scheme PayFlowDemo \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="build/Build/Products/Release-iphoneos/PayFlowDemo.app"
OUT="PayFlowDemo-unsigned.ipa"

if [ ! -d "$APP" ]; then
  echo "没有找到 $APP" >&2
  exit 1
fi

rm -rf build/ipa "$OUT"
mkdir -p build/ipa/Payload
cp -R "$APP" build/ipa/Payload/

(
  cd build/ipa
  zip -qry "../../$OUT" Payload
)

echo "==> 完成：$OUT"
echo "   用 Sideloadly / AltStore 自签后安装到 iPhone。"
