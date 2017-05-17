export PKG_CONFIG_LIBDIR=$(pwd)/contrib/i686-w64-mingw32/lib/pkgconfig
mkdir -p win32
cd win32
../extras/package/win32/configure.sh --host=i686-w64-mingw32 --build=x86_64-pc-linux-gnu --disable-lua --disable-live555
