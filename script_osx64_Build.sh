rm -rdf contrib/contrib/x86_64-apple-darwin10

mkdir -p build
cd build
../extras/package/macosx/build.sh -k /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/
