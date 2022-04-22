#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
export NEED_SRC=false
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=A-12

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d Neo-Launcher ] || git clone --recursive git@github.com:NeoApplications/Neo-Launcher -b $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd Neo-Launcher
git submodule update --init --recursive .
chmod +x gradlew

export JAVA_HOME=/usr/lib/jvm/java-14-openjdk

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
	./gradlew clean assembleAospWithQuickstepOmega
	cp -f ./build/outputs/apk/aospWithQuickstepOmega/release/NeoLauncher*.apk $PRODUCT_OUT_PATH/NeoLauncher.apk
else
	./gradlew clean assembleAospWithQuickstepOmega
	cp -f ./build/outputs/apk/lawnWithQuickstep/debug/NeoLauncher*.apk $PRODUCT_OUT_PATH/NeoLauncher.apk
fi
