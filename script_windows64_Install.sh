make -C win32/ package-win-common
mkdir -p /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64/lib
cp win32/vlc-3.0.0-git/libvlc*.dll /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64/lib
cp -Rf win32/vlc-3.0.0-git/plugins /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64
cp -f generateLib_x64.bat /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64/lib
