mkdir -p contrib/win32
cd contrib/win32
../bootstrap --host=x86_64-w64-mingw32
make fetch
make
