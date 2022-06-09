#!/bin/sh
[ -z "$VERSION" ] && VERSION=v1.4.19
MYDIR="$(dirname $(realpath $0))"
SOURCE=git@github.com:vector-im/element-android.git
MODULE=element
. ${MYDIR}/envsetup.sh

checkout
force_java_version 12

sed -i	-e "s,^signing.element.storePath=.*,signing.element.storePath=$CERT_STORE," \
	-e "s,^signing.element.storePassword=.*,signing.element.storePassword=$CERT_PW," \
	-e "s,^signing.element.keyId=.*,signing.element.keyId=apps," \
	-e "s,^signing.element.keyPassword=.*,signing.element.keyPassword=$CERT_PW," \
	gradle.properties
sed -i	-e 's,// signingConfig,signingConfig,' vector/build.gradle

./gradlew assembleFDroidRelease
output vector/build/outputs/apk/fdroid/release/vector-fdroid-arm64-v8a-release.apk
