#!/bin/sh
[ -z "$VERSION" ] && VERSION=v0.97
SOURCE=git@github.com:imshyam/mintube
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout
force_java_version 14
# The included gradle wrapper is too old to even start,
# but the gradle configs don't work for latest and greatest.
# So let's go for something in between.
rm -rf gradlew* gradle
gradle wrapper --gradle-version=6.3

add_certs_to_gradle app/build.gradle

./gradlew assembleRelease
output app/build/outputs/apk/release/app-release.apk
