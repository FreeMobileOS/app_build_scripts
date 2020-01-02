#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
OUTAPK=./app/k9mail/build/outputs/apk/release/k9mail-release.apk
MODULE=k9mail
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d $MODULE ] || git clone git@github.com:FreeMobileOS/k9mail --branch 5.703 --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
        CERTS="$(pwd)"/secret-keys
fi

cd $MODULE
# Use generic names
sed -i -e 's,app_name">K-9 Mail,app_name">E-Mail,' app/ui/src/main/res/values-gl/strings.xml
sed -i -e 's,shortcuts_title">K-9 Accounts,shortcuts_title">E-Mail Accounts,' app/ui/src/main/res/values/strings.xml
sed -i -e 's,unread_widget_label">K-9 Unread,unread_widget_label">Unread email,' app/ui/src/main/res/values/strings.xml

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
