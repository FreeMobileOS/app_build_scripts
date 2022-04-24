#!/bin/sh
[ -z "$VERSION" ] && VERSION="2.5.1"
SOURCE=git@github.com:AntennaPod/AntennaPod
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout

# Use a generic name...
autoTranslate core/src/main/res/values/strings.xml app_name Podcasts
autoTranslate app/src/main/res/values/strings.xml app_name Podcasts

force_java_version 14

cat >>gradle.properties <<EOF
releaseStoreFile=$CERT_STORE
releaseStorePassword=$CERT_PW
releaseKeyAlias=apps
releaseKeyPassword=$CERT_PW
EOF

./gradlew assembleRelease
output app/build/outputs/apk/free/release/app-free-release.apk
