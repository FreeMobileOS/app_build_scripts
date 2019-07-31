#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=./app/build/outputs/apk/release/app-release.apk
MODULE=forecastie
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=fmo-v1.10.4

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:FreeMobileOS/forecastie.git $MODULE --branch $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
	. ${CERTS}/services/openweathermap
	# We prefer using our own API key because there's a limited number
	# of permitted requests using the API key per minute, and upstream
	# Forecastie tends to get too many, causing errors.
	sed -i -e "s,3e29e62e2ddf6dd3d2ebd28aed069215,$KEY," forecastie/app/src/main/res/values/keys.xml
fi

cd $MODULE

# change app name to weather
sed -i -e 's,app_name">Forecastie,app_name">Weather,' app/src/main/res/values/strings.xml

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
    echo "Warning: Debug build is not supported"
fi
