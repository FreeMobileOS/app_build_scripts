#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=app/build/outputs/apk/release/app-release.apk
MODULE=Lawnchair
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=fmo-1.1.0.1872

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
# change targetSdkVersion to fix crash error on 8.1.0
T_OLD="argetSdkVersion 27"
T_NEW="argetSdkVersion 22"
sed -i "s/$T_OLD/$T_NEW/g" app/build.gradle

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
# insert signature to lawnfeed also
		cat >>lawnfeed/build.gradle <<EOF
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
    cp -f lawnfeed/build/outputs/apk/release/lawnfeed-release.apk $PRODUCT_OUT_PATH/Lawnfeed.apk
else
	./gradlew clean assembleDebug
	cp -f app/build/outputs/apk/debug/app-debug.apk $PRODUCT_OUT_PATH/$MODULE.apk
    cp -f lawnfeed/build/outputs/apk/debug/lawnfeed-debug.apk $PRODUCT_OUT_PATH/Lawnfeed.apk
fi
