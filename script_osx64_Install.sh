# create temp directory, copy libraries&headers
mkdir -p temp_Mac
mkdir -p temp_Mac/lib
mkdir -p temp_Mac/plugins
mkdir -p temp_Mac/include
cp -Rf build/vlc_install_dir/lib/*.dylib temp_Mac/lib
cp -Rf build/vlc_install_dir/lib/vlc/plugins temp_Mac
cp -Rf build/vlc_install_dir/include temp_Mac

# clean temp directory
find temp_Mac/plugins -type f -name '*.la' -delete
rm -f temp_Mac/plugins/plugins.dat

# apply script to filter plugins non-LGPL or non-royaltyFree
cd temp_Mac
python ../VLC-make-free.py
cd ..

# clean Gaia and copy
rm -Rf /Volumes/data/releases/KVLC/master/Mac
mkdir -p /Volumes/data/releases/KVLC/master/Mac
cp -Rf temp_Mac/* /Volumes/data/releases/KVLC/master/Mac

# destroy temp directory
rm -Rf temp_Mac
