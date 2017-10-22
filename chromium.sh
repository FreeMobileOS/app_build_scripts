#!/bin/sh
# For a list of current Android compatible versions, see
# http://omahaproxy.appspot.com/
GN_ARGS='target_os="android" target_cpu="arm64"'
# FIXME should probably switch to
# GN_ARGS='target_os="android" target_cpu="arm64" proprietary_codecs=true ffmpeg_branding="ChromeOS" enable_hevc_demuxing=true'
# to get more codecs supported... But this causes ffmpeg build breakages without patching the code

MYDIR="$(dirname $(realpath $0))"
cd $MYDIR
export NEED_NDK=false
export NEED_SRC=false
export NEED_ROOTPATH=false
. ./envsetup.sh
unset NEED_NDK
unset NEED_SRC
unset NEED_ROOTPATH

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=/opt/legacy:$PATH:$(pwd)/depot_tools
mkdir chromium
cd chromium
fetch --nohooks --no-history android
cd src
echo "target_os = [ 'android' ]" >>../.gclient
gclient sync
gclient runhooks
# Version numbers from http://omahaproxy.appspot.com/
#git checkout -b stable tags/61.0.3163.98

gn gen --args="${GN_ARGS}" out/Release
ninja -C out/Release monochrome_public_apk

[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -e secret-keys/aosp/fmo.jks ]; then
	APKSIGN_CMD_PATH=$(find $ANDROID_HOME -name apksigner | head -n 1)
	$APKSIGN_CMD_PATH sign --ks secret-keys/aosp/fmo.jks --ks-pass file:secret-keys/aosp/password --out $PRODUCT_OUT_PATH/chromium.apk chromium/src/out/Release/apks/MonochromePublic.apk
else
	cp chromium/src/out/Release/apks/MonochromePublic.apk $PRODUCT_OUT_PATH/chromium.apk
fi
