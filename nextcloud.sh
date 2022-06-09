#!/bin/sh
[ -z "$VERSION" ] && VERSION=stable-3.20.1
SOURCE=https://github.com/nextcloud/android.git
MODULE=nextcloud
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout

add_certs_to_gradle "app/build.gradle"
	
echo org.gradle.jvmargs=-Xmx4G >>gradle.properties
GRADLE_OPTS="-Xmx4G" ./gradlew clean assembleRelease
output build/outputs/apk/fmo/release/fmo-release-*.apk
cleanup
