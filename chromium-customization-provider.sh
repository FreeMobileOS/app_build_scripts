#!/bin/sh

add_signature()
{
	p_gradle=$1
	if [ -n "$CERTS" ]; then
		P="$(cat $CERTS/aosp/password)"
		if ! grep -q fmo.jks $p_gradle; then
			cat >>$p_gradle <<EOF
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
	fi
}

MYDIR="$(dirname $(realpath $0))"
OUTAPK=./app/build/outputs/apk/release/app-release.apk
MODULE=chromium-customization-provider
REPO_NAME=https://github.com/FreeMobileOS/chromium_customization_provider.git

[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=master

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"

# app
if [ ! -d $MODULE ]; then
git clone $REPO_NAME $MODULE --branch $VERSION --single-branch
fi

# sign key
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

cd $MODULE

if [ -n "$CERTS" ]; then
	add_signature "app/build.gradle"
	
	./gradlew clean assembleRelease
	cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
	echo "Warning: Debug build is not supported"
fi
