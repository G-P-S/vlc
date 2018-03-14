#!/bin/bash

mkdir -p contrib/win32
cd contrib/win32
../bootstrap --host=x86_64-w64-mingw32
make prebuilt
ln -sf 'x86_64-w64-mingw32' ../i686-w64-mingw32
wget -P ~/Downloads https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v5.0.0.tar.bz2
tar xf ~/Downloads/mingw-w64-v5.0.0.tar.bz2 -C ~/Downloads/
yes | cp -rf -dir ~/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/wrl ../x86_64-w64-mingw32/include/wrl
yes | cp -rf ~/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/roapi.h ../x86_64-w64-mingw32/include/roapi.h
yes | cp -rf ~/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite.h ../x86_64-w64-mingw32/include/dwrite.h
yes | cp -rf ~/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite_1.h ../x86_64-w64-mingw32/include/dwrite_1.h
yes | cp -rf ~/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite_2.h ../x86_64-w64-mingw32/include/dwrite_2.h
rm -f ~/Downloads/mingw-w64-v5.0.0.tar.bz2
rm -drf ~/Downloads/mingw-w64-v5.0.0
