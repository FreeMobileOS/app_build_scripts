#!/bin/sh
[ -z "$VERSION" ] && VERSION=2022.03.23-4-android
SOURCE=git@github.com:organicmaps/organicmaps
MYDIR="$(dirname $(realpath $0))"
MODULE=organicmaps
. ${MYDIR}/envsetup.sh

checkout
# Use generic names
autoTranslate android/res/values/strings.xml app_name Maps
# We've generated a translatable name -- so we have to prevent gradle from
# overwriting it with a static name
sed -i -e "/app_name/d" android/build.gradle

# And replace the signing keys with ours...
sed -i -e "s|storeFile.*|storeFile file(\"$CERT_STORE\")|" android/build.gradle
sed -i -e "s|storePassword.*|storePassword \"$CERT_PW\"|" android/build.gradle
sed -i -e "s|keyAlias.*|keyAlias \"apps\"|" android/build.gradle
sed -i -e "s|keyPassword.*|keyPassword \"$CERT_PW\"|" android/build.gradle

./configure.sh

force_java_version 18

export PATH=$ANDROID_SDK/cmake/3.18.1/bin:$PATH
./tools/android/set_up_android.py --sdk "$ANDROID_HOME"
cd android
./gradlew assembleFdroidRelease
output build/outputs/apk/fdroid/release/OrganicMaps-*-fdroid-release.apk
cleanup
