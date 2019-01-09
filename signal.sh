#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

VERSION=4.31.6

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d Signal-Android ] || git clone --depth 1 -b v${VERSION} git@github.com:signalapp/Signal-Android
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

cd Signal-Android

# let's built signal to avoid gcm communication
sed -i -e 's,PlayServicesUtil.getPlayServicesStatus(this);,PlayServicesStatus.MISSING;,' src/org/thoughtcrime/securesms/RegistrationActivity.java

# let's fix expiry period
sed -i -e 's,return 90 - age;,return 390 - age;,' src/org/thoughtcrime/securesms/util/Util.java

# fix sign build. We are using our signature
sed -i -e '/task.finalizedBy signProductionPlayRelease/d' build.gradle
sed -i -e '/task.finalizedBy signProductionWebsiteRelease/d' build.gradle

sed -i -e 's,app_name">Signal,app_name">Instant Messenger,' res/values/strings.xml

# add applicationId to resolve conflicts with playstore version.
if ! grep -q com.fmo.signal build.gradle; then
    sed -i '/'$VERSION'/a \\tapplicationId "com.fmo.signal"' build.gradle
fi

if [ -n "$CERTS" ]; then
        P="$(cat $CERTS/aosp/password)"
        if ! grep -q fmo.jks build.gradle; then
                cat >>build.gradle <<EOF
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
    echo "release build"
	./gradlew assembleRelease
	cp -f build/outputs/apk/website/release/Signal-website-release-$VERSION.apk $PRODUCT_OUT_PATH/signal.apk
else
    echo "debug build"
	./gradlew assembleDebug
	cp -f build/outputs/apk/website/release/Signal-website-debug-$VERSION.apk $PRODUCT_OUT_PATH/signal.apk
fi
