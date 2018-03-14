#!/bin/bash

export PKG_CONFIG_LIBDIR=~./contrib/x86_64-w64-mingw32/lib/pkgconfig

./bootstrap

mkdir win32
cd win32

../extras/package/win32/configure.sh --host=x86_64-w64-mingw32 --build=x86_64-pc-linux-gnu --disable-lua --disable-live555 --disable-faad --disable-chromecast
 make package-win-strip -j8
