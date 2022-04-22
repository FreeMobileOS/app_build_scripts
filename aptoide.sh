#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
export NEED_SRC=false
MODULE=aptoide
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:Aptoide/aptoide-client-v8 --branch 'v9.20.4.0(10115)' --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

git reset --hard

cd aptoide-client-v8
# Use generic names
autoTranslate app/src/vanilla/res/values/strings.xml app_name "App Market"
autoTranslate app/src/vanillaProd/res/values/strings.xml app_name "App Market"

patch -p1 <"$MYDIR"/patches/aptoide/fix-build-by-disabling-donations.patch

export JAVA_HOME=/usr/lib/jvm/java-12-openjdk


if [ -n "$CERTS" ]; then
        P="$(cat $CERTS/aosp/password)"
        if ! grep -q fmo.jks build.gradle; then
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
        ./gradlew clean assembleVanillaProd
        cp -f ./app/build/outputs/apk/vanillaProd/release/vanilla_prod_release_*.apk $PRODUCT_OUT_PATH/$MODULE.apk
else
    echo "Warning: Debug build is not supported"
fi
