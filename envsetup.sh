#!/bin/sh
# script to setup environment for app build

function warn_msg()
{
    echo "$@" 1>&2;
}

function usage()
{
cat <<EOF
Invoke "source ./envsetup.sh" from your shell to set the app build enviornment:
Arguments:
	--sdk <SDK PATH>	            ; set android sdk path
	--ndk <NDK PATH>	            ; set android ndk path
    --and <ANDROID SOURCE PATH>     ; Android source path for signing
    --approot <APPS ROOT>           : parent location where applications are clonned
	--out <OUT DIR>		            ; out directory where generated app will gets copiedi,
                                      if not set default location is ./out
EOF
# TODO:
# should we add croot
# option to signature path
}

function set_javahome()
{
    if [ -z "$JAVA_HOME" ]; then
        JAVA_HOME="$(realpath $(dirname $(readlink -f $(which javac)))/..)"
	[ -d "$JAVA_HOME" ] || unset JAVA_HOME
    fi
    if [ -z "$JAVA_HOME" ]; then
        echo "Enter the directory of your OpenJDK installation:"
	read JAVA_HOME
    fi
    export JAVA_HOME
}

function set_ndkpath()
{
# ndk path
    if [ -z "$ANDROID_NDK_PATH" ] ; then
        [ -d /opt/android-ndk ] && ANDROID_NDK_PATH=/opt/android-ndk
        [ -d ~/Android/Sdk/ndk-bundle ] && ANDROID_NDK_PATH=$(realpath ~/Android/Sdk/ndk-bundle)
    fi
    if [ -z "$ANDROID_NDK_PATH" ] ; then
        echo "Enter Android ndk path:"
        read ANDROID_NDK_PATH
        # TODO: validate the NDK path
    fi
    echo "NDK:$ANDROID_NDK_PATH"
    export ANDROID_NDK_PATH=$ANDROID_NDK_PATH
}

function set_sdkpath()
{
# sdk path
    if [ -z "$ANDROID_SDK_PATH" ] ; then
        [ -d /opt/android-sdk-linux ] && ANDROID_SDK_PATH=/opt/android-sdk-linux
        [ -d /opt/android-sdk ] && ANDROID_SDK_PATH=/opt/android-sdk
        [ -d ~/Android/Sdk ] && ANDROID_SDK_PATH=$(realpath ~/Android/Sdk)
    fi
    if [ -z "$ANDROID_SDK_PATH" ] ; then
        echo "Enter Android sdk path:"
        read ANDROID_SDK_PATH
        # TODO: validate the SDK path
    fi

    echo "SDK:$ANDROID_SDK_PATH"
    export ANDROID_SDK_PATH=$ANDROID_SDK_PATH
}

function setpath()
{
    export ANDROID_HOME=$ANDROID_SDK_PATH
    export ANDROID_NDK_HOME=$ANDROID_NDK_PATH
    export PATH="$ANDROID_HOME/tools:$ANDROID_NDK_PATH/:$PATH"
}

function set_outpath()
{
# sdk path
    if [ -z "$PRODUCT_OUT_PATH" ] ; then
        PRODUCT_OUT_PATH="$PWD/out"
        mkdir -p $PRODUCT_OUT_PATH
    fi

    echo "output:$PRODUCT_OUT_PATH"
    export PRODUCT_OUT_PATH=$PRODUCT_OUT_PATH
}

function set_androidsrcpath() {
# android path
    echo "android source path (make sure build is done before) for signing apk using platform key"
    if [ -z "$ANDROID_SRC_PATH" ] ; then
        echo "Enter Android src path:"
        read srcpath
         ANDROID_SRC_PATH=$srcpath
        # TODO: validate the source path
    fi

    echo "Android source:$ANDROID_SRC_PATH"
    export ANDROID_SRC_PATH=$ANDROID_SRC_PATH
}

function set_approotpath() {
# application root path
    if [ -z "$APP_ROOT_PATH" ] ; then
        echo "Enter App root path:"
        read APP_ROOT_PATH
    fi
    echo "Application root:$APP_ROOT_PATH"
    export APP_ROOT_PATH=$APP_ROOT_PATH
}

function unset_var()
{
    unset ANDROID_SDK_PATH
    unset ANDROID_NDK_PATH
    unset ANDROID_SRC_PATH
    unset APP_ROOT_PATH
    unset PRODUCT_OUT_PATH
}
############################################################################
# entry point of script: main
############################################################################

# TODO LIST:
# logic to download app repository and switch to required branch
unset_var

while [ $# -gt 0 ]; do
    case "$1" in
        --sdk)
        ANDROID_SDK_PATH=$2
        ;;
        --ndk)
        ANDROID_NDK_PATH=$2
        ;;
        --and)
        export ANDROID_SRC_PATH=$2
        ;;
        --approot)
        export APP_ROOT_PATH=$2
        ;;
        --out)
        PRODUCT_OUT_PATH=$2
        ;;
        -h|--help)
        usage
        return 0
        ;;
    esac
    shift
done

# set JAVA_HOME
set_javahome

# set ndk path
set_ndkpath

# set sdk path
set_sdkpath

# set android source path
set_androidsrcpath

if [ -z "$ANDROID_NDK_PATH" -o -z "$ANDROID_SDK_PATH" ]; then
	warn_msg "ANDROID_NDK and ANDROID_SDK is not set."
	warn_msg "Set it to NDK and SDK directories."
	usage
    unset_var
    return 0
fi

#set outpath
set_outpath

#set path
setpath

#set app root
set_approotpath
