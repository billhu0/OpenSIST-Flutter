#!/bin/zsh

flutter build ios --release --no-codesign
rm -rf Payload
cp -r build/ios/iphoneos/Runner.app Payload
zip -r "OpenSIST-beta-unsigned.ipa" Payload
