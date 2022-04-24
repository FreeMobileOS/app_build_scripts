#!/bin/sh
VERSION=5.6.0
SOURCE=git@github.com:SimpleMobileTools/Simple-Flashlight.git
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

force_java_version 16

checkout
cat >keystore.properties <<EOF
keyAlias=apps
keyPassword=$CERT_PW
storeFile=$CERT_STORE
storePassword=$CERT_PW
EOF
./gradlew clean assembleRelease
output app/build/outputs/apk/fdroid/release/flashlight-fdroid-release.apk
cleanup
