#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
export NEED_SRC=false
OUTAPK=./app/k9mail/build/outputs/apk/release/k9mail-release.apk
MODULE=k9mail
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:k9mail/k-9 --branch 6.000 --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

cd k-9
# Use generic names
autoTranslate app/ui/legacy/src/main/res/values/strings.xml app_name E-Mail
autoTranslate app/ui/legacy/src/main/res/values/strings.xml shortcuts_title "E-Mail Accounts"
autoTranslate app/ui/legacy/src/main/res/values/strings.xml unread_widget_label "Unread email"


if [ -n "$CERTS" ]; then
        P="$(cat $CERTS/aosp/password)"
        if ! grep -q fmo.jks app/k9mail/build.gradle; then
                cat >>app/k9mail/build.gradle <<EOF
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
