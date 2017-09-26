make -C win32/ package-win-common
mkdir -p /mnt/tera/data/releases/KVLC/vlc3_master/LibVLC/lib/Windows/win32/lib
cp win32/vlc-3.0.0-git/libvlc*.dll /mnt/tera/data/releases/KVLC/vlc3_master/LibVLC/lib/Windows/win32/lib
cp -Rf win32/vlc-3.0.0-git/plugins /mnt/tera/data/releases/KVLC/vlc3_master/LibVLC/lib/Windows/win32
cp -f generateLib_win32.bat /mnt/tera/data/releases/KVLC/vlc3_master/LibVLC/lib/Windows/win32/lib
