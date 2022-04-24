#!/bin/sh
[ -z "$VERSION" ] && VERSION=v1.19.1
SOURCE=https://github.com/KDE/kdeconnect-android
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout
add_certs_to_gradle build.gradle
force_java_version 14
./gradlew assembleRelease

output build/outputs/apk/release/kdeconnect-android-release.apk
cleanup
