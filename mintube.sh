#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d mintube ] || git clone git@github.com:imshyam/mintube --branch v0.97 --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd mintube
export JAVA_HOME=/usr/lib/jvm/java-14-openjdk
# The included gradle wrapper is too old to even start,
# but the gradle configs don't work for latest and greatest.
# So let's go for something in between.
rm -rf gradlew* gradle
gradle wrapper --gradle-version=6.3

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
	cp -f app/build/outputs/apk/release/app-release.apk $PRODUCT_OUT_PATH/mintube.apk
else
	./gradlew assembleDebug
	cp -f app/build/outputs/apk/debug/app-debug.apk $PRODUCT_OUT_PATH/mintube-debug.apk
fi
