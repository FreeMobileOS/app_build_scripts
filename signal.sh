#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

VERSION=4.24.5

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d Signal-Android ] || git clone --depth 1 -b v${VERSION} git@github.com:WhisperSystems/Signal-Android
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd Signal-Android

# let's built signal to avoid gcm communication
sed -i -e 's,PlayServicesUtil.getPlayServicesStatus(this);,PlayServicesStatus.MISSING;,' src/org/thoughtcrime/securesms/RegistrationActivity.java

autoTranslate res/values/strings.xml app_name Instant Messenger

# add applicationId to resolve conflicts with playstore version.
sed -i '/'$VERSION'/a \\tapplicationId "com.fmo.signal"' build.gradle

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	cat >signing.properties <<EOF
STORE_FILE=$CERTS/aosp/fmo.jks
STORE_PASSWORD=$P
KEY_ALIAS=apps
KEY_PASSWORD=$P
EOF
	./gradlew assembleRelease
	cp -f build/outputs/apk/website/release/Signal-website-release-$VERSION.apk $PRODUCT_OUT_PATH/signal.apk
else
	./gradlew assembleDebug
	cp -f build/outputs/apk/website/release/Signal-website-debug-$VERSION.apk $PRODUCT_OUT_PATH/signal.apk
fi
