#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=play-services-core/build/outputs/apk/release/play-services-core-release.apk
MODULE=GmsCore
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=fmo-master

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:FreeMobileOS/android_packages_apps_GmsCore.git $MODULE --branch $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

cd $MODULE

# pre-build setup
gmscore_root=$(pwd)
gmscore_dir=play-services-core
gmscore_build=$gmscore_dir/build
JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

touch play-services-core/user.gradle
rm -Rf $gmscore_build
echo "sdk.dir=$ANDROID_SDK_HOME" > $gmscore_root/local.properties
git submodule update --recursive --init

if [ -n "$CERTS" ]; then
        P="$(cat $CERTS/aosp/password)"
        if ! grep -q fmo.jks play-services-core/user.gradle; then
                cat >>play-services-core/user.gradle <<EOF
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
        echo "gmsroot is:$gmscore_root"
        cd $gmscore_root/$gmscore_dir
        ../gradlew assembleRelease
        cd $MODULE
        cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
    echo "Warning: Debug build is not supported"
fi
