#!/bin/sh
set -e
set -x

info()
{
    local green="\033[1;32m"
    local normal="\033[0m"
    echo "[${green}build${normal}] $1"
}

ARCH="x86_64"
MINIMAL_OSX_VERSION="10.7"
OSX_VERSION=`xcrun --show-sdk-version`
#OSX_KERNELVERSION=`uname -r | cut -d. -f1`
OSX_KERNELVERSION=15
SDKROOT=`xcode-select -print-path`/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$OSX_VERSION.sdk

usage()
{
cat << EOF
usage: $0 [options]

Build vlc in the current directory

OPTIONS:
   -h            Show some help
   -q            Be quiet
   -r            Rebuild everything (tools, contribs, vlc)
   -c            Recompile contribs from sources
   -k <sdk>      Use the specified sdk (default: $SDKROOT)
   -a <arch>     Use the specified arch (default: $ARCH)
EOF

}

spushd()
{
    pushd "$1" > /dev/null
}

spopd()
{
    popd > /dev/null
}

while getopts "hvrck:a:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         q)
             set +x
             QUIET="yes"
         ;;
         r)
             REBUILD="yes"
         ;;
         c)
             CONTRIBFROMSOURCE="yes"
         ;;
         a)
             ARCH=$OPTARG
         ;;
         k)
             SDKROOT=$OPTARG
         ;;
     esac
done
shift $(($OPTIND - 1))

if [ "x$1" != "x" ]; then
    usage
    exit 1
fi

#
# Various initialization
#

out="/dev/stdout"
if [ "$QUIET" = "yes" ]; then
    out="/dev/null"
fi

info "Building VLC for the Mac OS X"

spushd `dirname $0`/../../..
vlcroot=`pwd`
spopd

builddir=`pwd`

info "Building in \"$builddir\""

TRIPLET=$ARCH-apple-darwin$OSX_KERNELVERSION

export CC="`xcrun --find clang`"
export CXX="`xcrun --find clang++`"
export OBJC="`xcrun --find clang`"
export OSX_VERSION
export SDKROOT
export PATH="${vlcroot}/extras/tools/build/bin:${vlcroot}/contrib/${TRIPLET}/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:${PATH}"

# Select avcodec flavor to compile contribs with
export USE_FFMPEG=1

# The following symbols do not exist on the minimal macOS version (10.7), so they are disabled
# here. This allows compilation also with newer macOS SDKs.
# Added symbols between 10.11 and 10.12
export ac_cv_func_basename_r=no
export ac_cv_func_clock_getres=no
export ac_cv_func_clock_gettime=no
export ac_cv_func_clock_settime=no
export ac_cv_func_dirname_r=no
export ac_cv_func_getentropy=no
export ac_cv_func_mkostemp=no
export ac_cv_func_mkostemps=no

# Added symbols between 10.7 and 10.11
export ac_cv_func_ffsll=no
export ac_cv_func_flsll=no
export ac_cv_func_fdopendir=no
export ac_cv_func_openat=no # Disables fstatat as well


# libnetwork does not exist yet on 10.7 (used by libcddb)
export ac_cv_lib_network_connect=no

#
# vlc/extras/tools
#

info "Building building tools"
spushd "${vlcroot}/extras/tools"
./bootstrap > $out
if [ "$REBUILD" = "yes" ]; then
    make clean
fi
make > $out
spopd

core_count=`sysctl -n machdep.cpu.core_count`
let jobs=$core_count+1

#
# vlc/contribs
#

info "Building contribs"
spushd "${vlcroot}/contrib"
mkdir -p contrib-$TRIPLET && cd contrib-$TRIPLET
../bootstrap --build=$TRIPLET --host=$TRIPLET > $out
if [ "$REBUILD" = "yes" ]; then
    make clean
fi
if [ "$CONTRIBFROMSOURCE" = "yes" ]; then
    make fetch
    make -j$jobs
else
if [ ! -e "../$TRIPLET" ]; then
    make prebuilt > $out
fi
fi
spopd


#
# vlc/bootstrap
#

info "Bootstrap-ing configure"
spushd "${vlcroot}"
if ! [ -e "${vlcroot}/configure" ]; then
    ${vlcroot}/bootstrap > $out
fi
spopd


#
# vlc/configure
#

if [ "${vlcroot}/configure" -nt Makefile ]; then

  ${vlcroot}/extras/package/macosx/configure.sh \
      --build=$TRIPLET \
      --host=$TRIPLET \
      --with-macosx-version-min=$MINIMAL_OSX_VERSION \
      --with-macosx-sdk=$SDKROOT > $out
fi


#
# make
#


if [ "$REBUILD" = "yes" ]; then
    info "Running make clean"
    make clean
fi

info "Running make -j$jobs"
make -j$jobs

info "Preparing VLC.app"
make VLC.app
