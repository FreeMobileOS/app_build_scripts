#!/bin/sh
[ -z "$VERSION" ] && VERSION='v9.20.4.0(10115)'
MYDIR="$(dirname $(realpath $0))"
SOURCE=git@github.com:Aptoide/aptoide-client-v8
MODULE=aptoide
. ${MYDIR}/envsetup.sh

checkout
# Use generic names
autoTranslate app/src/vanilla/res/values/strings.xml app_name "App Market"
autoTranslate app/src/vanillaProd/res/values/strings.xml app_name "App Market"

force_java_version 12

sed -i	-e "s,^STORE_FILE_VANILLA=.*,STORE_FILE_VANILLA=$CERT_STORE," \
	-e "s,^STORE_PASSWORD_VANILLA=.*,STORE_PASSWORD_VANILLA=$CERT_PW," \
	-e "s,^KEY_ALIAS_VANILLA=.*,KEY_ALIAS_VANILLA=apps," \
	-e "s,^KEY_PASSWORD_VANILLA=.*,KEY_PASSWORD_VANILLA=$CERT_PW," \
	gradle.properties
./gradlew clean assembleVanillaProd
output ./app/build/outputs/apk/vanillaProd/release/vanilla_prod_release_*.apk
cleanup
