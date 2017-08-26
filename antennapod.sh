#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d AntennaPod ] || git clone git@github.com:FreeMobileOS/AntennaPod
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd AntennaPod

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	if ! grep -q fmo.jks app/build.gradle; then
		cat >>app/build.gradle <<EOF
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
	fi
	./gradlew assembleRelease
	# Alternatively, instead of adding to build.gradle above:
	#	$ANDROID_HOME/build-tools/26.0.0/zipalign -v -p 8 app/build/outputs/apk/app-release-unsigned.apk app/build/outputs/apk/app-release-unsigned-aligned.apk
	#	$ANDROID_HOME/build-tools/25.0.3/apksigner sign --ks ${CERTS}/aosp/fmo.jks --out app/build/outputs/apk/AntennaPod.apk app/build/outputs/apk/app-release-unsigned-aligned.apk
	#	cp -f app/build/outputs/apk/AntennaPod.apk $PRODUCT_OUT_PATH
	cp -f app/build/outputs/apk/app-free-release.apk $PRODUCT_OUT_PATH/AntennaPod.apk
else
	./gradlew assembleDebug
	cp -f app/build/outputs/apk/app-free-debug.apk $PRODUCT_OUT_PATH/AntennaPod.apk
fi
