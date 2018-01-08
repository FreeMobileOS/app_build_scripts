#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=build/outputs/apk/release/kdeconnect-android-release.apk
MODULE=kdeconnect-android
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:FreeMobileOS/kdeconnect-android.git $MODULE --branch fmo-v1.6.6 --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
echo "Preparing>>..$MODULE"

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
	./gradlew clean assembleRelease
	cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
    echo "WARNING: Debug build is not supported"
fi
