#!/bin/sh
# script to setup environment for app build

export FMO_SCRIPT_DIR="$(realpath $(dirname $(echo ${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]})))"

function warn_msg()
{
	echo "$@" 1>&2;
}

# Translate text...
# Usage:
# translate LANGCODE text
#	LANGCODE: language code of target language
#	text: English text
#
# Return:
#	Translated text in language specified by LANGCODE
#
# Example:
#	translate de Linux forever
# (should return Linux für immer)
function translate()
{
	local lng="$1"
	if echo $lng |grep -q '^..[_-]r..$'; then
		# Android-ish LANG-rREGION isn't recognized by translate
		# but standard-ish LANG-REGION is...
		lng=$(echo $lng |cut -b1-2)-$(echo $lng |cut -b5-6)
	fi
	shift
	local X="$@|$lng|"
	if grep -q "^$X" $FMO_SCRIPT_DIR/translation-overrides; then
		echo -n $(grep "^$X" $FMO_SCRIPT_DIR/translation-overrides |cut -d'|' -f3-)
	else
		wget -qO - -U "Mozilla/5.0" "http://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=${lng}&dt=t&q=$(echo $@ |sed -e 's, ,+,g')" |cut -d'"' -f2
	fi
}

# Automatically translate text in Android resource files
# Usage:
# autoTranslate file ID text
#	file: XML resource file
#	ID: resource identifier
#	text: Text
#
# Example:
#	autoTranslate forecastie/app/src/main/res/values/strings.xml app_name Weather
# (should change the name of the forecastie app to "Weather", with
# appropriate translations to any langauge forecastie provides
# translations for)
function autoTranslate()
{
	local F="$1"
	shift
	local ID="$1"
	shift
	# Replace string in untranslated file...
	sed -i -E "s|<string name=\"$ID\">.*</string>|<string name=\"$ID\">$@</string>|" $F
	local BASE=$(dirname $(dirname $F))
	local FN=$(basename $F)
	for i in ${BASE}/values-*/$FN; do
		[ -e "$i" ] || continue
		local LANGCODE=`echo $i |sed -e "s,${BASE}/values-,,;s,/.*,,"`
		if grep -q "<string name=\"$ID\">" $i; then
			sed -i -E "s|<string name=\"$ID\">.*</string>|<string name=\"$ID\">$(translate $LANGCODE $@)</string>|" $i
		else
			sed -i -e "/<\/resources>/i	<string name=\"$ID\">$(translate $LANGCODE $@)<\/string>" $i
		fi
		echo $LANGCODE: $(translate $LANGCODE $@)
	done
}

function update_parameter()
{
	xsltproc - "$1" >"$1.new" <<EOF
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:android="http://schemas.android.com/apk/res/android">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="SwitchPreference[@android:key='$2']">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="android:defaultValue">
				<xsl:value-of select="'$3'"/>
			</xsl:attribute>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="Preference[@android:key='$2']">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="android:defaultValue">
				<xsl:value-of select="'$3'"/>
			</xsl:attribute>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
EOF
	mv -f "$1.new" "$1"
}

function usage()
{
cat <<EOF
Invoke "source ./envsetup.sh" from your shell to set the app build enviornment:
Arguments:
	--sdk <SDK PATH>				; set android sdk path
	--ndk <NDK PATH>				; set android ndk path
	--and <ANDROID SOURCE PATH>	 ; Android source path for signing
	--approot <APPS ROOT>		   : parent location where applications are clonned
	--out <OUT DIR>					; out directory where generated app will gets copiedi,
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
	if [ -n "$ANDROID_HOME" -o -n "$ANDROID_NDK_PATH" ]; then
		export PATH="$ANDROID_HOME/tools:$ANDROID_NDK_PATH/:$PATH"
	fi
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
	[ -z "$ANDROID_SRC_PATH" -a -d "/media/space/AOSP/fmo-8.1.0" ] && export ANDROID_SRC_PATH=/media/space/AOSP/fmo-8.1.0
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
	if [ "$APP_ROOT_PATH" = "prompt" ] ; then
		echo "Enter App root path:"
		read APP_ROOT_PATH
	elif [ -z "$APP_ROOT_PATH" ]; then
		export APP_ROOT_PATH="`mktemp -d /tmp/appbuild.XXXXXX`"
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
[ "$NEED_JAVA_HOME" = "false" ] || set_javahome

# set ndk path
[ "$NEED_NDK" = "false" ] || set_ndkpath

# set sdk path
[ "$NEED_SDK" = "false" ] || set_sdkpath

# set android source path
[ "$NEED_SRC" = "false" ] || set_androidsrcpath

if [ "$NEED_NDK" != "false" -a -z "$ANDROID_NDK_PATH" ] || [ "$NEED_SDK" != "false" -a -z "$ANDROID_SDK_PATH" ]; then
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
[ "$NEED_ROOTPATH" = "false" ] || set_approotpath
