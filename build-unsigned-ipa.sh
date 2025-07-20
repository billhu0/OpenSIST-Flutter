#!/bin/zsh

rm -rf Payload
rm -rf build
rm -f "OpenSIST-beta-unsigned.ipa"
flutter build ios --release --no-codesign
cp -r build/ios/iphoneos/Runner.app Payload
zip -r MyApp.ipa Payload
