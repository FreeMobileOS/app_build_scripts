#!/bin/sh
# For a list of current Android compatible versions, see
# http://omahaproxy.appspot.com/
GN_ARGS='target_os="android" target_cpu="arm64" is_debug=false is_official_build=true is_chrome_branded=false enable_resource_whitelist_generation=true ffmpeg_branding="Chrome" proprietary_codecs=true enable_remoting=true'
# FIXME should probably switch to
# GN_ARGS='target_os="android" target_cpu="arm64" proprietary_codecs=true ffmpeg_branding="ChromeOS" enable_hevc_demuxing=true'
# to get more codecs supported... But this causes ffmpeg build breakages without patching the code
# 
# Monochrome is supposed to be a combined Chromium and Webview APK. Current tests show it not
# actually replacing the system webview though.
[ -z "$USE_MONOCHROME" ] && USE_MONOCHROME=false
# Available channels: head, canary, dev, beta, stable
[ -z "$CHANNEL" ] && CHANNEL=head

MYDIR="$(dirname $(realpath $0))"
cd $MYDIR
export NEED_NDK=false
export NEED_SRC=false
export NEED_ROOTPATH=false
. ./envsetup.sh
unset NEED_NDK
unset NEED_SRC
unset NEED_ROOTPATH

set -x
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=/opt/legacy:$PATH:$(pwd)/depot_tools
mkdir chromium
cd chromium
# May want to add --no-history -- will that break branches?
fetch --nohooks android
cd src
echo "target_os = [ 'android' ]" >>../.gclient
if [ "$CHANNEL" = "head" ]; then
	echo Using Chromium HEAD...
	gclient sync
	gclient runhooks
else
	VERSIONS=$(wget -O - "https://omahaproxy.appspot.com/all?os=android&channel=$CHANNEL" |tail -n1)
	# VERSIONS should now be a CSV saying something like
	# android,beta,62.0.3202.52,62.0.3202.45,10/12/17,10/05/17,fa6a5d87adff761bc16afc5498c3f5944c1daa68,499098,4f1faed364af4797f7a86a908b85b369d9892539,3202,6.2.414.30
	# Meaning:
	# 1 os
	# 2 channel
	# 3 current_version
	# 4 previous_version
	# 5 current_reldate
	# 6 previous_reldate
	# 7 branch_base_commit
	# 8 branch_base_position
	# 9 branch_commit
	# 10 true_branch
	# 11 v8_version
	CURRENT_VERSION=$(echo ${VERSIONS} |cut -d, -f3)
	echo Using Chromium ${CURRENT_VERSION}...
	COMMIT=$(echo ${VERSIONS} |cut -d, -f9)
	gclient sync -r ${COMMIT}
	gclient runhooks
fi

# As of AOSP O 8.0.0_r17, the bundled system WebView's versionCode is 303012550
# We need to outnumber that if we want to install an update...
# We should also outnumber our own previous builds, so let's put a date code in there.
# picking 379828897 as a base because it's sufficiently larger than 303012550 and it
# will give our first build, done on 2017/11/03, a nice round number.
VERCODE=$((379828897+$(date +%Y%m%d)))
find . -name AndroidManifest.xml |xargs sed -i -e "s,android:versionCode=\"1\",android:versionCode=\"$VERCODE\",g"

gn gen --args="${GN_ARGS}" out/Release
if $USE_MONOCHROME; then
	ninja -C out/Release monochrome_public_apk
else
	ninja -C out/Release system_webview_apk chrome_modern_public_apk
fi

[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -e secret-keys/aosp/fmo.jks ]; then
	APKSIGN_CMD_PATH=$(find $ANDROID_HOME -name apksigner | head -n 1)
	if $USE_MONOCHROME; then
		$APKSIGN_CMD_PATH sign --ks secret-keys/aosp/fmo.jks --ks-pass file:secret-keys/aosp/password --out $PRODUCT_OUT_PATH/chromium.apk out/Release/apks/MonochromePublic.apk
	else
		for i in out/Release/apks/*.apk; do
			$APKSIGN_CMD_PATH sign --ks secret-keys/aosp/fmo.jks --ks-pass file:secret-keys/aosp/password --out $PRODUCT_OUT_PATH/$(basename "$i") "$i"
		done
	fi
else
	if $USE_MONOCHROME; then
		cp out/Release/apks/MonochromePublic.apk $PRODUCT_OUT_PATH/chromium.apk
	else
		cp out/Release/apks/*.apk $PRODUCT_OUT_PATH/
	fi
fi
