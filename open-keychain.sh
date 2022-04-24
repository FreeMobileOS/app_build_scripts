#!/bin/sh
[ -z "$VERSION" ] && VERSION=v5.7.5
SOURCE=git@github.com:open-keychain/open-keychain
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout
autoTranslate OpenKeychain/src/main/res/values/strings.xml app_name "Encryption"

# FIXME stop forcing old javac when gradle's copy of groovyjarjarasm starts
# supporting something newer
force_java_version 14

cat >>gradle.properties <<EOF

# The extra newline above is required because upstream doesn't have an EOL
# at the end of the original file. Don't remove it.
signingStoreLocation=$CERT_STORE
signingStorePassword=$CERT_PW
signingKeyAlias=apps
signingKeyPassword=$CERT_PW
EOF

./gradlew assembleRelease
output OpenKeychain/build/outputs/apk/fdroid/release/OpenKeychain-fdroid-release.apk
cleanup
