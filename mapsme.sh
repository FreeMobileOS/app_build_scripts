#!/bin/sh

# utility function to add signature file
add_keystore()
{
	p_gradle=$1
	cp $CERTS/aosp/fmo.jks ./fmo.jks
	if [ -n "$CERTS" ]; then
		P="$(cat $CERTS/aosp/password)"
			cat >>$p_gradle <<EOF
ext {
    spropStorePassword= "$P"
    spropKeyPassword= "$P"
    spropKeyAlias= "apps"
    spropStoreFile= "$(pwd)/fmo.jks"
}
EOF
	fi
}

MYDIR="$(dirname $(realpath $0))"
OUTAPK=app/build/outputs/apk/release/app-release.apk
MODULE=omim
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=fmo-py-modules-0.2.11

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:FreeMobileOS/$MODULE --depth 1 -b $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
git submodule init
git submodule update

export NDK_ABI=arm64-v8a
echo | ./configure.sh
./tools/android/set_up_android.py --sdk $ANDROID_HOME --ndk $ANDROID_NDK_PATH
sed -i -e 's,#define DEFAULT_URLS_JSON.*,#define DEFAULT_URLS_JSON \"[\\"http://direct.mapswithme.com/\\" ]\",' private.h
sed -i -e 's|cppFlags .*|&, "-DANDROID64"|' android/build.gradle
sed -i -e 's|cFlags .*|&, "-DANDROID64"|' android/build.gradle

# Note: To fix build error for release-82
echo "#define GOOGLE_WEB_CLIENT_ID \"\" " >> private.h
cd android

# Use generic name
autoTranslate res/values/strings.xml app_name Maps

if [ -n "$CERTS" ]; then
    rm secure.properties
    add_keystore "secure.properties" 
fi

./gradlew -Parm64=1 -Darm64=1 assembleWebRelease
cp build/outputs/apk/android-web-release-*-*.apk $PRODUCT_OUT_PATH/mapsme.apk
