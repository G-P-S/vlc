mkdir -p contrib/win32
cd contrib/win32
../bootstrap --host=x86_64-w64-mingw32
make prebuilt
wget -P $HOME/Downloads https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v5.0.0.tar.bz2
tar xf $HOME/Downloads/mingw-w64-v5.0.0.tar.bz2 -C $HOME/Downloads/
yes | cp -rf -dir $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/wrl ../x86_64-w64-mingw32/include/wrl
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/roapi.h ../x86_64-w64-mingw32/include/roapi.h
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite.h ../x86_64-w64-mingw32/include/dwrite.h
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite_1.h ../x86_64-w64-mingw32/include/dwrite_1.h
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite_2.h ../x86_64-w64-mingw32/include/dwrite_2.h
rm -f $HOME/Downloads/mingw-w64-v5.0.0.tar.bz2
rm -drf $HOME/Downloads/mingw-w64-v5.0.0
