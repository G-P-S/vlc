mkdir -p /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64/lib
cp win32/vlc-2.2.6/libvlc*.dll /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64/lib
cp win32/vlc-2.2.6/sdk/lib/libvlc*.lib /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64/lib
cp -Rf win32/vlc-2.2.6/plugins /mnt/tera/data/releases/KVLC/vlc2/LibVLC/lib/Windows/x64

mkdir -p /mnt/tera/data/releases/KVLC/vlc2/LibVLC/include/vlc/plugins
cp -Rf win32/vlc-2.2.6/sdk/include /Volumes/data/releases/KVLC/vlc2/LibVLC/include/
