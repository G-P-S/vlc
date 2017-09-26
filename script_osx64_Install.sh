mkdir -p /Volumes/data/releases/KVLC/vlc3_master/LibVLC/lib/Mac/lib
cp -Rf build/vlc_install_dir/lib/*.dylib /Volumes/data/releases/KVLC/vlc3_master/LibVLC/lib/Mac/lib
cp -Rf build/vlc_install_dir/lib/vlc/plugins /Volumes/data/releases/KVLC/vlc3_master/LibVLC/lib/Mac/plugins
find /Volumes/data/releases/KVLC/vlc3_master/LibVLC/lib/Mac/plugins -type f -name '*.la' -delete
