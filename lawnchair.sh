#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=app/build/outputs/apk/release/app-release.apk
MODULE=Lawnchair
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=fmo-1.1.0.1742

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:FreeMobileOS/$MODULE -b $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
# Permissions seem to be messed up in upstream's git repository
chmod +x gradlew

# require to package with sign other than travis
export TRAVIS_EVENT_TYPE="pull_request"

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
	./gradlew clean assembleRelease
	cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
	./gradlew clean assembleDebug
	cp -f app/build/outputs/apk/debug/app-debug.apk $PRODUCT_OUT_PATH/$MODULE.apk
fi
