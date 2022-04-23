#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
MODULE=organicmaps
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone --recurse-submodules git@github.com:organicmaps/organicmaps --branch 2022.03.23-4-android --single-branch --filter=blob:limit=128k --depth=1 --shallow-submodules
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
	P="$(cat $CERTS/aosp/password)"
fi

cd organicmaps
# Use generic names
autoTranslate android/res/values/strings.xml app_name Maps
# We've generated a translatable name -- so we have to prevent gradle from
# overwriting it with a static name
sed -i -e "/app_name/d" android/build.gradle

if [ -n "$CERTS" ]; then
	# And replace the signing keys with ours...
	sed -i -e "s|storeFile.*|storeFile file(\"$CERTS/aosp/fmo.jks\")|" android/build.gradle
	sed -i -e "s|storePassword.*|storePassword \"$P\"|" android/build.gradle
	sed -i -e "s|keyAlias.*|keyAlias \"apps\"|" android/build.gradle
	sed -i -e "s|keyPassword.*|keyPassword \"$P\"|" android/build.gradle
fi

./configure.sh

export PATH=$ANDROID_SDK/cmake/3.18.1/bin:$PATH
#export JAVA_HOME=/usr/lib/jvm/java-12-openjdk
./tools/android/set_up_android.py --sdk "$ANDROID_HOME"
cd android
./gradlew assembleFdroidRelease
cp build/outputs/apk/fdroid/release/OrganicMaps-*-fdroid-release.apk ${PRODUCT_OUT_PATH}/OrganicMaps.apk
