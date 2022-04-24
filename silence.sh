#!/bin/sh
[ -z "$VERSION" ] && VERSION=v0.16.12-unstable
SOURCE=https://git.silence.dev/Silence/Silence-Android
MODULE=Silence
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout
force_java_version 12

cat >signing.properties <<EOF
STORE_FILE=$CERT_STORE
STORE_PASSWORD=$CERT_PW
KEY_ALIAS=apps
KEY_PASSWORD=$CERT_PW
EOF

./gradlew clean assembleRelease
output build/outputs/apk/release/Silence-release.apk
cleanup
