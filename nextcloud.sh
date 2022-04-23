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
OUTAPK=./build/outputs/apk/fmo/release/fmo-release-30050190.apk
MODULE=nextcloud
REPO_NAME=https://github.com/nextcloud/android.git

[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=stable-3.19.1

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"

# FIXME
#export JAVA_HOME=/usr/lib/jvm/java-16-openjdk

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

# create fmo flavor
mv src/generic src/fmo
sed -i -e 's,generic,fmo,' build.gradle

if [ -n "$CERTS" ]; then
	add_signature "build.gradle"
	
	echo org.gradle.jvmargs=-Xmx4G >>gradle.properties
	GRADLE_OPTS="-Xmx4G" ./gradlew clean assemblefmoRelease
	cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
	echo "Warning: Debug build is not supported"
fi
