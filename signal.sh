#!/bin/sh
[ -z "$VERSION" ] && VERSION=v5.36.2
SOURCE=git@github.com:signalapp/Signal-Android
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout
force_java_version 14

add_certs_to_gradle app/build.gradle
./gradlew assembleRelease
output app/build/outputs/apk/websiteProd/release/Signal-Android-website-prod-arm64-v8a-release-*.apk
cleanup
