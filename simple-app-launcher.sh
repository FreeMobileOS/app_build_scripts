#!/bin/sh

add_keystore()
{
	p_gradle=$1
	cp $CERTS/aosp/fmo.jks ./fmo.jks
	if [ -n "$CERTS" ]; then
		P="$(cat $CERTS/aosp/password)"
			cat >>$p_gradle <<EOF
storePassword=$P
keyPassword=$P
keyAlias=apps
storeFile=../fmo.jks
EOF
	fi
}

MYDIR="$(dirname $(realpath $0))"
OUTAPK=app/build/outputs/apk/release/app-launcher-release.apk
MODULE=simple-app-launcher
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=5.0.1

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"

# app
if [ ! -d $MODULE ]; then
git clone https://github.com/SimpleMobileTools/Simple-App-Launcher.git $MODULE --branch $VERSION --single-branch
fi

# sign key
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

cd $MODULE

# create gradle.properties to fix kotlin build
cat >>gradle.properties <<EOF
android.useAndroidX=true
android.enableJetifier=true
EOF

# "draw.pro" is available on playstore, but we use f-droid
sed -i -e 's,com.simplemobiletools.draw.pro,com.simplemobiletools.draw,' app/src/main/kotlin/com/simplemobiletools/applauncher/helpers/Constants.kt
sed -i -e 's,com.simplemobiletools.draw.pro,com.simplemobiletools.draw,' app/src/main/kotlin/com/simplemobiletools/applauncher/extensions/Resources.kt

# use f-droid, no google play store
sed -i -e 's,play.google.com/store/apps/details?id=,f-droid.org/en/packages/,' app/src/main/kotlin/com/simplemobiletools/applauncher/activities/MainActivity.kt

if [ -n "$CERTS" ]; then
	add_keystore "keystore.properties"
	
	./gradlew clean assembleRelease
	cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
	echo "Warning: Debug build is not supported"
fi
