mkdir -p /mnt/tera/data/releases/KVLC/master/LibVLC/lib/Windows/x64/lib
cp win32/vlc-3.0.0-git/libvlc*.dll /mnt/tera/data/releases/KVLC/master/LibVLC/lib/Windows/x64/lib
cp win32/vlc-3.0.0-git/sdk/lib/libvlc*.lib /mnt/tera/data/releases/KVLC/master/LibVLC/lib/Windows/x64/lib
cp -Rf win32/vlc-3.0.0-git/plugins /mnt/tera/data/releases/KVLC/master/LibVLC/lib/Windows/x64

mkdir -p /mnt/tera/data/releases/KVLC/master/LibVLC/include/vlc/plugins
cp -Rf win32/vlc-3.0.0-git/sdk/include /mnt/tera/data/releases/KVLC/master/LibVLC/
