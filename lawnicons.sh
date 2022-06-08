#!/bin/sh
[ -z "$VERSION" ] && VERSION=develop
MYDIR="$(dirname $(realpath $0))"
SOURCE=git@github.com:LawnchairLauncher/lawnicons
. ${MYDIR}/envsetup.sh

checkout

# require to package with sign other than travis
#export TRAVIS_EVENT_TYPE="pull_request"
add_certs_to_gradle_kts app/build.gradle.kts

./gradlew assemble
output ./app/build/outputs/apk/release/app-release.apk
cleanup
