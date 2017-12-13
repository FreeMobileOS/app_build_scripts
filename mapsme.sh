#!/bin/sh
if [ ! -d omim ]; then
	git clone --depth 1 -b fmo-release-80 git@github.com:FreeMobileOS/omim
	cd omim
	git submodule init
	git submodule update
	cd ..
fi

cd omim
export NDK_ABI=arm64-v8a
echo | ./configure.sh
./tools/android/set_up_android.py --sdk ~/Android/Sdk --ndk ~/Android/Sdk/ndk-bundle
sed -i -e 's,#define DEFAULT_URLS_JSON.*,#define DEFAULT_URLS_JSON \"[\\"http://direct.mapswithme.com/\\" ]\",' private.h
sed -i -e 's|cppFlags .*|&, "-DANDROID64"|' android/build.gradle
sed -i -e 's|cFlags .*|&, "-DANDROID64"|' android/build.gradle
cd android

[ -d secret-keys ] || git clone git@github.com:OpenMandrivaAssociation/secret-keys
if [ -d secret-keys ]; then
	CERTS="$(pwd)"/secret-keys
fi
if [ -n "$CERTS" ]; then
	P="$(cat $CERTS/aosp/password)"
	if ! grep -q fmo.jks app/build.gradle; then
		cat >>app/build.gradle <<EOF
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
fi

./gradlew -Parm64=1 -Darm64=1 clean assembleWebRelease
cp build/outputs/apk/android-web-release-*-*.apk ../../out/mapsme.apk
