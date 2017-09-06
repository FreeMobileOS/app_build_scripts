#!/bin/sh
MYDIR="$(dirname $(realpath $0))"
[ -z "$ANDROID_HOME" ] && . ${MYDIR}/envsetup.sh
[ -z "$APP_ROOT_PATH" ] && APP_ROOT_PATH=$MYDIR

mkdir -p "$APP_ROOT_PATH"
cd "$APP_ROOT_PATH"
[ -d vlc-android ] || git clone https://code.videolan.org/videolan/vlc-android.git --branch 2.1.9 --single-branch
[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi

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

cd vlc-android

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
	sh compile.sh -a arm64-v8a --release
	cp -f vlc-android/build/outputs/apk/VLC-Android-2.1.9-ARMv8.apk $PRODUCT_OUT_PATH/vlc.apk
else
	sh compile.sh -a arm64-v8a
	cp -f vlc-android/build/outputs/apk/VLC-Android-2.1.9-ARMv8.apk $PRODUCT_OUT_PATH/vlc-debug.apk
fi
