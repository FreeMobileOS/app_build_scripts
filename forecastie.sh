#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d forecastie ] || git clone --depth 1 git@github.com:FreeMobileOS/forecastie
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
	. ${CERTS}/services/openweathermap
	# We prefer using our own API key because there's a limited number
	# of permitted requests using the API key per minute, and upstream
	# Forecastie tends to get too many, causing errors.
	sed -i -e "s,3e29e62e2ddf6dd3d2ebd28aed069215,$KEY," forecastie/app/src/main/res/values/keys.xml
fi

cd forecastie

# Use a generic name...
autoTranslate app/src/main/res/values/strings.xml app_name Weather

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
	#	$ANDROID_HOME/build-tools/25.0.3/apksigner sign --ks ${CERTS}/aosp/fmo.jks --out app/build/outputs/apk/forecastie.apk app/build/outputs/apk/app-release-unsigned-aligned.apk
	#	cp -f app/build/outputs/apk/forecastie.apk $PRODUCT_OUT_PATH
	cp -f app/build/outputs/apk/app-release.apk $PRODUCT_OUT_PATH/forecastie.apk
else
	./gradlew assembleDebug
	cp -f app/build/outputs/apk/app-debug.apk $PRODUCT_OUT_PATH/forecastie.apk
fi
