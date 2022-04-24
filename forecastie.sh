#!/bin/sh
[ -z "$VERSION" ] && VERSION=v1.22.1
SOURCE=git@github.com:martykan/forecastie.git
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh

checkout
if [ -e "${CERTS}/services/openweathermap" ]; then
	. ${CERTS}/services/openweathermap
	# We prefer using our own API key because there's a limited number
	# of permitted requests using the API key per minute, and upstream
	# Forecastie tends to get too many, causing errors.
	sed -i -e "s,66803bb34c2a6e2cfe7ad7e2beb619ec,$KEY," app/src/main/res/values/keys.xml
fi

wget https://github.com/martykan/forecastie/pull/673.patch
git apply 673.patch

# change app name to weather
autoTranslate app/src/main/res/values/strings_main_graphs_map_about.xml app_name Weather

add_certs_to_gradle app/build.gradle

force_java_version 8
./gradlew assembleRelease

output ./app/build/outputs/apk/release/app-release.apk
cleanup
