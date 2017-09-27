#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d terminal ] || git clone -b fmo-master git@github.com:FreeMobileOS/Android-Terminal-Emulator terminal
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd terminal
# Let's make it compatible with currernt AOSP...
find . -name "*.gradle" |xargs sed -i -e 's,compileSdkVersion 22,compileSdkVersion 26,g;s,targetSdkVersion 22,targetSdkVersion 26,g;s,buildToolsVersion \"22.0.1\",buildToolsVersion "26.0.1",g'

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	if ! grep -q fmo.jks build.gradle; then
		cat >>term/build.gradle <<EOF
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
	cp -f term/build/outputs/apk/term-release.apk $PRODUCT_OUT_PATH/terminal.apk
else
	./gradlew assembleDebug
	cp -f term/build/outputs/apk/term-debug.apk $PRODUCT_OUT_PATH/terminal.apk
fi
