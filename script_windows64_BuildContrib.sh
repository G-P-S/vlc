mkdir -p contrib/win32
cd contrib/win32
../bootstrap --host=x86_64-w64-mingw32 --disable-archive --disable-aa --disable-aribb25 --disable-aribsub --disable-avahi --disable-bluray --disable-bpg --disable-breakpad --disable-caca --disable-chromaprint --disable-chromecast --disable-dc1394 --disable-dv1394 --disable-dvdnav --disable-dvdread --disable-evas --disable-freerdp --disable-gme --disable-gnutls --disable-goom --disable-jpeg --disable-kwallet --disable-libass --disable-libcddb --disable-libgcrypt --disable-libtar --disable-libxml2 --disable-linsys --disable-lirc --disable-macosx --disable-macosx-avfoundation --disable-microdns --disable-minimal-macosx --disable-mtp --disable-ncurses --disable-notify --disable-opencv --disable-opensles --disable-osx-notifications --disable-png --disable-projectm --disable-qt --disable-samplerate --disable-screen --disable-secret --disable-shout --disable-sid --disable-skins2 --disable-soxr --disable-sparkle --disable-svg --disable-svgdec --disable-telx --disable-udev --disable-update-check --disable-upnp --disable-v4l2 --disable-vcd --disable-vnc --disable-vsxu --disable-zvbi
make fetch
sed -ie 's:/usr/include/wine/windows/:/usr/include/wine-development/windows/:g' ../src/d3d9/rules.mak && sed -ie 's:/usr/include/wine/windows/:/usr/include/wine-development/windows/:g' ../src/d3d11/rules.mak
make
wget -P $HOME/Downloads https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v5.0.0.tar.bz2
tar xf $HOME/Downloads/mingw-w64-v5.0.0.tar.bz2 -C $HOME/Downloads/
yes | cp -rf -dir $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/wrl ../x86_64-w64-mingw32/include/wrl
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/roapi.h ../x86_64-w64-mingw32/include/roapi.h
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite.h ../x86_64-w64-mingw32/include/dwrite.h
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite_1.h ../x86_64-w64-mingw32/include/dwrite_1.h
yes | cp -rf $HOME/Downloads/mingw-w64-v5.0.0/mingw-w64-headers/include/dwrite_2.h ../x86_64-w64-mingw32/include/dwrite_2.h
rm -f $HOME/Downloads/mingw-w64-v5.0.0.tar.bz2
rm -drf $HOME/Downloads/mingw-w64-v5.0.0
