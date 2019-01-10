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
OUTAPK=app/build/outputs/apk/standard/release/app-standard-release.apk
MODULE=davx5-ose
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=v2.2.2-ose

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"

# app
if [ ! -d $MODULE ]; then
git clone git@gitlab.com:bitfireAT/davx5-ose.git $MODULE --branch $VERSION --single-branch

# dependencies
git clone git@gitlab.com:bitfireAT/cert4android.git $MODULE/cert4android
git clone git@gitlab.com:bitfireAT/dav4jvm.git $MODULE/dav4jvm
git clone git@gitlab.com:bitfireAT/ical4android.git $MODULE/ical4android
git clone git@gitlab.com:bitfireAT/vcard4android.git $MODULE/vcard4android

fi

# sign key
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

cd $MODULE

if [ -n "$CERTS" ]; then
	add_signature "app/build.gradle"
	
    add_signature "cert4android/build.gradle"
	add_signature "ical4android/build.gradle"
	add_signature "vcard4android/build.gradle"
	./gradlew clean assembleRelease
	cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
	echo "Warning: Debug build is not supported"
fi
