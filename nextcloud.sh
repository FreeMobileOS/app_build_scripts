#!/bin/sh
[ -z "$VERSION" ] && VERSION=stable-3.19.1
SOURCE=https://github.com/nextcloud/android.git
MODULE=nextcloud
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout

# create fmo flavor
mv src/generic src/fmo
sed -i -e 's,generic,fmo,' build.gradle

add_certs_to_gradle "build.gradle"
	
echo org.gradle.jvmargs=-Xmx4G >>gradle.properties
GRADLE_OPTS="-Xmx4G" ./gradlew clean assemblefmoRelease
output build/outputs/apk/fmo/release/fmo-release-*.apk
cleanup
