#!/bin/sh
[ -z "$VERSION" ] && VERSION="v1.49.2"
SOURCE=git://git.code.sf.net/p/opencamera/code
MODULE=opencamera
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout
# We don't run on prehistoric AOSP -- using Camera2 is safe
sed -i -e 's,preference_camera_api_old,preference_camera_api_camera2,g' app/src/main/java/net/sourceforge/opencamera/PreferenceKeys.java
add_certs_to_gradle app/build.gradle

# FIXME stop forcing old javac when gradle's copy of groovyjarjarasm starts
# supporting something newer
force_java_version 16

./gradlew assembleRelease
output app/build/outputs/apk/release/app-release.apk
cleanup
