#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=vector/build/outputs/apk/fdroid/release/vector-fdroid-arm64-v8a-release.apk
MODULE=element
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=v1.4.12

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:vector-im/element-android.git $MODULE --branch $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

export JAVA_HOME=/usr/lib/jvm/java-12-openjdk

cd $MODULE

if [ -n "$CERTS" ]; then
        P="$(cat $CERTS/aosp/password)"
        if ! grep -q fmo.jks vector/build.gradle; then
                cat >>vector/build.gradle <<EOF
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
        ./gradlew clean
        ./gradlew assembleFDroidRelease
        cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
    echo "Warning: Debug build is not supported"
fi
