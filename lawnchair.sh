#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
MODULE=lawnchair
export NEED_SRC=false
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=12-dev

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone --recursive git@github.com:LawnchairLauncher/$MODULE -b $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
git submodule update --init --recursive .
# Permissions seem to be messed up in upstream's git repository
chmod +x gradlew
# change targetSdkVersion to fix crash error on 8.1.0
#T_OLD="argetSdkVersion 27"
#T_NEW="argetSdkVersion 22"
#sed -i "s/$T_OLD/$T_NEW/g" app/build.gradle

# require to package with sign other than travis
export TRAVIS_EVENT_TYPE="pull_request"

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	if ! grep -q fmo.jks build.gradle; then
		cat >>build.gradle <<EOF
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
	./gradlew clean assembleLawnWithQuickstepRelease
	cp -f ./build/outputs/apk/lawnWithQuickstep/release/Lawnchair*.apk $PRODUCT_OUT_PATH/$MODULE.apk
else
	./gradlew clean assembleLawnWithQuickstepDebug
	cp -f ./build/outputs/apk/lawnWithQuickstep/debug/Lawnchair*.apk $PRODUCT_OUT_PATH/$MODULE.apk
fi
