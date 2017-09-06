#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d PassAndroid ] || git clone git@github.com:ligi/PassAndroid
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd PassAndroid

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	cat >signing.properties <<EOF
STORE_FILE=$CERTS/aosp/fmo.jks
STORE_PASSWORD=$P
KEY_ALIAS=apps
KEY_PASSWORD=$P
EOF
	./gradlew assembleRelease
	cp -f android/build/outputs/apk/PassAndroid-3.4.1-noMaps-noAnalytics-forFDroid-release-unsigned.apk $PRODUCT_OUT_PATH/PassAndroid.apk
else
	./gradlew assembleDebug
	cp -f android/build/outputs/apk/PassAndroid-3.4.1-noMaps-noAnalytics-forFDroid-release-unsigned.apk $PRODUCT_OUT_PATH/PassAndroid.apk
fi
