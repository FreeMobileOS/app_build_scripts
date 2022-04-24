#!/bin/sh
[ -z "$VERSION" ] && VERSION=12-dev
MYDIR="$(dirname $(realpath $0))"
SOURCE=git@github.com:LawnchairLauncher/lawnchair
. ${MYDIR}/envsetup.sh

checkout
# Permissions seem to be messed up in upstream's git repository
chmod +x gradlew

cat >keystore.properties <<EOF
storeFile=$CERT_STORE
storePassword=$CERT_PW
keyAlias=apps
keyPassword=$CERT_PW
EOF

# require to package with sign other than travis
#export TRAVIS_EVENT_TYPE="pull_request"

./gradlew assembleLawnWithQuickstepRelease
output ./build/outputs/apk/lawnWithQuickstep/release/Lawnchair*.apk
cleanup
