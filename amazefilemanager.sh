#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=./app/build/outputs/apk/fdroid/release/app-fdroid-release.apk
MODULE=amazefilemanager
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=v3.6.7

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:TeamAmaze/AmazeFileManager.git $MODULE --branch $VERSION --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
echo "HACL>>..$MODULE"

# FIXME Stupid, dumb Android SDK freaks out on any JDK not
# 3 decades old
export JAVA_HOME=/usr/lib/jvm/java-1.8.0

if [ -n "$CERTS" ]; then
        P="$(cat $CERTS/aosp/password)"
        if ! grep -q fmo.jks app/build.gradle; then
                cat >>app/build.gradle <<EOF
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
	cat >signing.properties <<EOF
STORE_FILE=$CERTS/aosp/fmo.jks
STORE_PASSWORD=$P
KEY_ALIAS=apps
KEY_PASSWORD=$P
EOF

        fi
        ./gradlew clean assembleFdroid
        cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
    echo "Warning: Debug build is not supported"
fi
