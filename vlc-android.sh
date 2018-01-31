#!/bin/sh
VERSION=2.9.0
MYDIR="$(dirname $(realpath $0))"
. ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d vlc-android ] || git clone https://code.videolan.org/videolan/vlc-android.git --branch ${VERSION} --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

if which apt-get 2>/dev/null; then
	# TODO : Install required packages for vlc and ndk14b
	echo "Installing missing dependencies if any..."

	PKGS='install automake ant autopoint cmake build-essential libtool patch pkg-config protobuf-compiler ragel subversion unzip git openjdk-8-jre openjdk-8-jdk'

	sudo apt-get -y install ${PKGS}

	# check for ndk version, build will work only with ndk14b
	flag=`echo $ANDROID_NDK_HOME|awk '{print match($0,"r14b")}'`
	if [ $flag -gt 0 ]; then
	    echo "required ndk is in place"
	    export ANDROID_NDK=$ANDROID_NDK_HOME
	    export ANDROID_SDK=$ANDROID_HOME
	else
	    echo "required ndk version is:ndk14b"
	    echo "download ndk14b and set ANDROID_NDK_HOME again"
	    exit 1
	fi
fi

[ -z "$ANDROID_SDK" ] && export ANDROID_SDK="$ANDROID_SDK_PATH"
[ -z "$ANDROID_NDK" ] && export ANDROID_NDK="$ANDROID_NDK_PATH"

cd vlc-android
echo Using SDK $ANDROID_SDK
echo Using NDK $ANDROID_NDK
git clone https://git.videolan.org/git/vlc/vlc-3.0.git vlc
cd vlc
git checkout -b vlc-android $(cat compile.sh |grep ^TESTED_HASH |cut -d= -f2)
cd ..

for i in ${MYDIR}/patches/vlc/*.patch; do
	PN=$(basename $i |cut -d- -f1)
	echo "Applying patch $PN"
	patch -p1 -b -z .$PN~ <${i} || exit 1
done

if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	if ! grep -q fmo.jks vlc-android/build.gradle; then
		cat >>vlc-android/build.gradle <<EOF
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
	sh compile.sh -a arm64-v8a --release 2>&1 |tee ${MYDIR}/vlc-build.log
	cp -f vlc-android/build/outputs/apk/vanillaARMv8/release/VLC-Android-${VERSION}-ARMv8.apk $PRODUCT_OUT_PATH/vlc.apk
else
	sh compile.sh -a arm64-v8a
	cp -f vlc-android/build/outputs/apk/vanillaARMv8/*/VLC-Android-${VERSION}-ARMv8.apk $PRODUCT_OUT_PATH/vlc-debug.apk
fi

# VLC builds start a gradle daemon that needs to be killed
# when we're done -- otherwise future gradle invokations
# will refer to a temporary directory that may well be gone.
GRADLE="$(ps x |grep gradle |grep ${APP_ROOT_PATH} |awk '{ print $1; }')"
[ -n "${GRADLE}" ] && kill ${GRADLE}
