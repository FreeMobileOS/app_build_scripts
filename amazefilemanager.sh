#!/bin/sh
[ -z "$VERSION" ] && VERSION=v3.6.7
SOURCE=git@github.com:TeamAmaze/AmazeFileManager.git
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

# FIXME Stupid, dumb Android SDK freaks out on any JDK not
# 3 decades old
force_java_version 8

checkout

cat >signing.properties <<EOF
STORE_FILE=$CERT_STORE
STORE_PASSWORD=$CERT_PW
KEY_ALIAS=apps
KEY_PASSWORD=$CERT_PW
EOF

./gradlew clean assembleFdroid
output app/build/outputs/apk/fdroid/release/app-fdroid-release.apk

cleanup
