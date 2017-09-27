#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=./app/build/outputs/apk/app-release.apk
MODULE=fdroidclient
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone https://gitlab.com/fdroid/fdroidclient.git --branch 1.0-alpha3 --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
echo "HACL>>..$MODULE"

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
    echo "WARNING: Debug build is not supported"
fi