#!/bin/sh
[ -z "$VERSION" ] && VERSION=A-12
SOURCE=git@github.com:NeoApplications/Neo-Launcher
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh


checkout
force_java_version 14
add_certs_to_gradle build.gradle
chmod +x gradlew

./gradlew assembleAospWithQuickstepOmega
output ./build/outputs/apk/aospWithQuickstepOmega/release/NeoLauncher*.apk
cleanup
