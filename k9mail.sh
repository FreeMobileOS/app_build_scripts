#!/bin/sh
[ -z "$VERSION" ] && VERSION=6.000
MYDIR="$(dirname $(realpath $0))"
SOURCE=git@github.com:k9mail/k-9
MODULE=k9mail
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh

checkout

# Use generic names
autoTranslate app/ui/legacy/src/main/res/values/strings.xml app_name E-Mail
autoTranslate app/ui/legacy/src/main/res/values/strings.xml shortcuts_title "E-Mail Accounts"
autoTranslate app/ui/legacy/src/main/res/values/strings.xml unread_widget_label "Unread email"

cat >>gradle.properties <<EOF
storeFile=$CERT_STORE
storePassword=$CERT_PW
keyAlias=apps
keyPassword=$CERT_PW
EOF

./gradlew assembleRelease
output ./app/k9mail/build/outputs/apk/release/k9mail-release.apk
cleanup
exit 0

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
else
    echo "Warning: Debug build is not supported"
fi
