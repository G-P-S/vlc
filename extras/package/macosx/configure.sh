#!/bin/sh

CFLAGS=${CFLAGS}
LDFLAGS=${LDFLAGS}

case "${ARCH}" in
    x86_64*)
        CFLAGS="${CFLAGS} -m64 -march=core2 -mtune=core2"
        LDFLAGS="${LDFLAGS} -m64"
        ;;
    *x86*)
        CFLAGS="${CFLAGS} -m32 -march=prescott -mtune=generic"
        LDFLAGS="${LDFLAGS} -m32"
        ;;
esac

OPTIONS="
        --prefix=`pwd`/vlc_install_dir
--host=x86_64-w64-mingw32 --build=x86_64-pc-linux-gnu --disable-archive --disable-aa --disable-aribb25 --disable-aribsub --disable-avahi --disable-bluray --disable-bpg --disable-breakpad --disable-caca --disable-chromaprint --disable-chromecast --disable-dc1394 --disable-dv1394 --disable-dvdnav --disable-dvdread --disable-evas --disable-freerdp --disable-gme --disable-gnutls --disable-goom --disable-jpeg --disable-kwallet --disable-libass --disable-libcddb --disable-libgcrypt --disable-libtar --disable-libxml2 --disable-linsys --disable-lirc --disable-macosx --disable-macosx-avfoundation --disable-microdns --disable-minimal-macosx --disable-mtp --disable-ncurses --disable-notify --disable-opencv --disable-opensles --disable-osx-notifications --disable-png --disable-projectm --disable-qt --disable-samplerate --disable-screen --disable-secret --disable-shout --disable-sid --disable-skins2 --disable-soxr --disable-sparkle --disable-svg --disable-svgdec --disable-telx --disable-udev --disable-update-check --disable-upnp --disable-v4l2 --disable-vcd --disable-vnc --disable-vsxu --disable-zvbi
        --with-macosx-version-min=10.7
"

export CFLAGS
export LDFLAGS

sh "$(dirname $0)"/../../../configure ${OPTIONS} $*
