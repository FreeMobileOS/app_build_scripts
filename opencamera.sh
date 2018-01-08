#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=app/build/outputs/apk/release/app-release.apk
MODULE=opencamera
. ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION="v1.42.1"

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone --depth 1 -b ${VERSION} git://git.code.sf.net/p/opencamera/code $MODULE
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
# We don't run on prehistoric AOSP -- using Camera2 is safe
update_parameter app/src/main/res/xml/preferences.xml preference_use_camera2 true
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
