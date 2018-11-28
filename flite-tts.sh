#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=./app/build/outputs/apk/release/app-release.apk
MODULE=flite-tts
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR
[ -z "$VERSION" ] && VERSION=master

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE/flite-engine ] || git clone git@github.com:FreeMobileOS/festvox-flite-engine.git $MODULE/flite-engine
[ -d $MODULE/Flite-TTS-Android ] || git clone git@github.com:FreeMobileOS/Flite-TTS-Android.git $MODULE/Flite-TTS-Android
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

# export required variables for build
export FLITEDIR=$APP_ROOT_PATH/$MODULE/flite-engine
export FLITE_APP_DIR=$APP_ROOT_PATH/$MODULE/Flite-TTS-Android
export ANDROID_NDK=$ANDROID_NDK_PATH

# build the tts engine
cd $FLITEDIR
./configure --with-langvox=android --target=armeabiv7a-android ; make clean ; make

# build app
cd $FLITE_APP_DIR

# remove previous build
rm -rf app/build
rm local.properties

# define local.properties
echo "sdk.dir=$ANDROID_SDK_PATH" > $FLITE_APP_DIR/local.properties
echo "ndk.dir=$ANDROID_SDK_PATH/ndk-bundle" >> $FLITE_APP_DIR/local.properties
echo "sdk-location=$ANDROID_SDK_PATH" >> local.properties

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
        fi
        ./gradlew clean assembleRelease
        cp -f $OUTAPK $PRODUCT_OUT_PATH/$MODULE.apk
else
    echo "Warning: Debug build is not supported"
fi
