#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d k9mail ] || git clone git@github.com:FreeMobileOS/k9mail --branch fmo-8.0.0 --single-branch 
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
    P="$(cat $CERTS/aosp/password)"
fi

cd k9mail

echo "Building k9mail.."
./gradlew clean assembleRelease

echo "zipalign k9mail.."
# Alternatively, instead of adding to build.gradle above:
zipalign -v -p 8 k9mail/build/outputs/apk/k9mail-release-unsigned.apk k9mail/build/outputs/apk/k9mail-release-unsigned-aligned.apk

echo "sigining k9mail..:$CERTS"
APKSIGN_CMD_PATH=$(find $ANDROID_HOME -name apksigner | head -n 1)
echo "APKSINGN PATH.:$APKSIGN_CMD_PATH"
$APKSIGN_CMD_PATH sign --ks ${CERTS}/aosp/fmo.jks --ks-pass file:$CERTS/aosp/password --out k9mail/build/outputs/apk/k9mail.apk k9mail/build/outputs/apk/k9mail-release-unsigned-aligned.apk

cp -f k9mail/build/outputs/apk/k9mail.apk $PRODUCT_OUT_PATH/k9mail.apk
