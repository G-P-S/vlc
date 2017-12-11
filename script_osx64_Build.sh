# fix error in configure.ac on C compiler
extras/tools/build/bin/automake --add-missing

mkdir -p build
cd build
../extras/package/macosx/build.sh
