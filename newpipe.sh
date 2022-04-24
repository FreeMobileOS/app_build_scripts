#!/bin/sh
[ -z "$VERSION" ] && VERSION=v0.22.2
SOURCE=git@github.com:TeamNewPipe/NewPipe.git
MYDIR="$(dirname $(realpath $0))"
MODULE=newpipe
. ${MYDIR}/envsetup.sh

checkout
force_java_version 14
add_certs_to_gradle app/build.gradle

./gradlew assembleRelease

output ./app/build/outputs/apk/release/app-release.apk
cleanup
