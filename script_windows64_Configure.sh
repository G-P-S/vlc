export PKG_CONFIG_LIBDIR=$(pwd)/contrib/x86_64-w64-mingw32/lib/pkgconfig
mkdir -p win32
cd win32
../extras/package/win32/configure.sh --host=x86_64-w64-mingw32 --build=x86_64-pc-linux-gnu  CFLAGS="-g" CXXFLAGS="-g" --enable-debug --disable-chromaprint --disable-dvdread --disable-shout --disable-mad --disable-faad
