#!/bin/sh
VERSION=6.18.1
SOURCE=git@github.com:SimpleMobileTools/Simple-Calendar.git
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
output app/build/outputs/apk/fdroid/release/calendar-fdroid-release.apk
