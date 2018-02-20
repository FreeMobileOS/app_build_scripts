#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION="1.6.4.5"

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d AntennaPod ] || git clone --depth 1 -b ${VERSION} git@github.com:AntennaPod/AntennaPod
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd AntennaPod

# Use a generic name...
sed -i -e 's,name="app_name" translate="false",name="app_name",g' core/src/main/res/values/strings.xml app/src/main/res/values/strings.xml
autoTranslate core/src/main/res/values/strings.xml app_name Podcasts
autoTranslate app/src/main/res/values/strings.xml app_name Podcasts

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
