#!/bin/sh
[ -z "$VERSION" ] && VERSION=3.5.7
SOURCE=git@github.com:ligi/PassAndroid
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh

checkout

autoTranslate android/src/main/res/values/strings.xml app_name Wallet

# FIXME use of CMSClassUnloadingEnabled
force_java_version 14

echo >>android/build.gradle # ****ing missing newline at end of file
add_certs_to_gradle android/build.gradle

# Allow the combination of Free and withMaps -- thanks, microG!
sed -i -e "s,|| (distribution == 'forFDroid' && maps == 'withMaps'),," android/build.gradle

./gradlew assembleRelease

output android/build/outputs/apk/withMapsNoAnalyticsForFDroid/release/PassAndroid-*-withMaps-noAnalytics-forFDroid-release.apk
cleanup
