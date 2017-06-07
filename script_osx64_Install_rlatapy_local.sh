rm -rdf ../../KolorEyes/KVideo/LibVLC/lib/Mac/lib
rm -rdf ../../KolorEyes/KVideo/LibVLC/lib/Mac/plugins

cp -Rf build/VLC.app/Contents/MacOS/lib ../../KolorEyes/KVideo/LibVLC/lib/Mac
cp -Rf build/VLC.app/Contents/MacOS/plugins ../../KolorEyes/KVideo/LibVLC/lib/Mac

rm -rdf ../../KolorEyes/KolorEyes/KolorEyesVideo360Apps/Qt/bin
