#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
export NEED_SRC=false
. ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=v5.7.5

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d open-keychain ] || git clone git@github.com:open-keychain/open-keychain --branch $VERSION --single-branch --depth 1
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd open-keychain
git submodule update --init --recursive

autoTranslate OpenKeychain/src/main/res/values/strings.xml app_name "Encryption"

# FIXME stop forcing old javac when gradle's copy of groovyjarjarasm starts
# supporting something newer
export JAVA_HOME=/usr/lib/jvm/java-14-openjdk

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	if ! grep -q fmo.jks OpenKeychain/build.gradle; then
		cat >>OpenKeychain/build.gradle <<EOF
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
	cp -f OpenKeychain/build/outputs/apk/fdroid/release/OpenKeychain-fdroid-release.apk $PRODUCT_OUT_PATH/open-keychain.apk
else
	./gradlew assembleDebug
	cp -f OpenKeychain/build/outputs/apk/OpenKeychain-fdroid-debug.apk $PRODUCT_OUT_PATH/open-keychain.apk
fi
