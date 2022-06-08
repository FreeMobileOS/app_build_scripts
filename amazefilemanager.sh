#!/bin/sh
[ -z "$VERSION" ] && VERSION=v3.7.0
SOURCE=git@github.com:TeamAmaze/AmazeFileManager.git
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

# https://youtrack.jetbrains.com/issue/KT-45545
force_java_version 14
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
