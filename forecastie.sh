#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=./app/build/outputs/apk/release/app-release.apk
MODULE=forecastie
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=v1.22.1

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:martykan/forecastie.git $MODULE --branch $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
	. ${CERTS}/services/openweathermap
	# We prefer using our own API key because there's a limited number
	# of permitted requests using the API key per minute, and upstream
	# Forecastie tends to get too many, causing errors.
	sed -i -e "s,66803bb34c2a6e2cfe7ad7e2beb619ec,$KEY," forecastie/app/src/main/res/values/keys.xml
fi

cd $MODULE

# change app name to weather
autoTranslate app/src/main/res/values/strings_main_graphs_map_about.xml app_name Weather

# FIXME stop forcing old javac when gradle's copy of groovyjarjarasm starts
# supporting something newer
export JAVA_HOME=/usr/lib/jvm/java-14-openjdk

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
