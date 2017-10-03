# create temp directory, copy libraries&headers
mkdir -p temp_Windows
mkdir -p temp_Windows/lib
mkdir -p temp_Windows/plugins
mkdir -p temp_Windows/include
cp win32/vlc-3.0.0-git/libvlc*.dll temp_Windows/lib
cp win32/vlc-3.0.0-git/sdk/lib/libvlc*.lib temp_Windows/lib
cp win32/vlc-3.0.0-git/plugins/* temp_Windows/plugins
cp win32/vlc-3.0.0-git/sdk/include/* temp_Windows/include

# apply script to filter plugins
cd temp_Windows
python ../VLC-make-free.py
cd ..

# clean Gaia and copy
rm -Rf /mnt/tera/data/releases/KVLC/master/Windows
mkdir -p /mnt/tera/data/releases/KVLC/master/Windows
cp -Rf temp_Windows/* /mnt/tera/data/releases/KVLC/master/Windows

# destroy temp directory
rm -Rf temp_Windows
