#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=3.4.5

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d PassAndroid ] || git clone --depth 1 -b ${VERSION} git@github.com:ligi/PassAndroid
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd PassAndroid
autoTranslate android/src/main/res/values/strings.xml app_name Wallet

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"

	cat >>android/build.gradle <<EOF
android {
	signingConfigs {
		release {
			storeFile file("$CERTS/aosp/fmo.jks")
			storePassword "$P"
			keyAlias "apps"
			keyPassword "$P"
		}
	}
	buildTypes {
		release {
			signingConfig signingConfigs.release
		}
	}
}
EOF
	cat >signing.properties <<EOF
STORE_FILE=$CERTS/aosp/fmo.jks
STORE_PASSWORD=$P
KEY_ALIAS=apps
KEY_PASSWORD=$P
EOF
	./gradlew assembleRelease
	cp -f android/build/outputs/apk/PassAndroid-*-noMaps-noAnalytics-forFDroid-release.apk $PRODUCT_OUT_PATH/PassAndroid.apk
else
	./gradlew assembleDebug
	cp -f android/build/outputs/apk/PassAndroid-*-noMaps-noAnalytics-forFDroid-release.apk $PRODUCT_OUT_PATH/PassAndroid.apk
fi
