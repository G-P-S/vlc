devDirKVideo='/media/sf_IntelOctoDev/KVideo/LibVLC'
devDirKED='/media/sf_IntelOctoDev/KolorEyes/KolorEyesVideo360Apps/Qt/bin'
#devDirVLCGopro='/media/sf_IntelOctoDev/../vlc_gopro'

make -C win32/ package-win-common

#copy headers
cp -R win32/vlc-3.0.0-git/sdk/include $devDirKVideo

#copy libvlc libs
cp win32/vlc-3.0.0-git/sdk/lib/libvlc*.lib $devDirKVideo/lib/Windows/x64/lib
cp win32/vlc-3.0.0-git/libvlc*.dll $devDirKVideo/lib/Windows/x64/lib
cp win32/vlc-3.0.0-git/libvlc*.dll $devDirKED

#copy all plugins
#cp -R win32/vlc-3.0.0-git/plugins $devDirKVideo/lib/Windows/x64

#copy direct3d9 plugin only into KVideo LibVLC directory and KED direcotry
cp win32/vlc-3.0.0-git/plugins/video_output/libdirect3d9_plugin.dll $devDirKVideo/lib/Windows/x64/plugins/video_output
cp win32/vlc-3.0.0-git/plugins/video_output/libdirect3d9_plugin.dll $devDirKED/plugins/video_output



# cp modules/video_output/win32/direct3d9.c $devDirKVideo





















