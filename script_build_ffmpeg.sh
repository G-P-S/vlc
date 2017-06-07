cd ../../ffmpeg

git clean -qffdx

# NOT working conf
#./configure --arch=x86_64 --target-os=darwin --disable-everything --enable-vda --enable-hwaccel --enable-hwaccel=vda --cpu=core2 --enable-pthreads

# Working conf without decoders
./configure --arch=x86_64 --target-os=darwin --enable-vda --enable-hwaccel=vda --enable-pthreads --enable-static --disable-shared \
			--disable-doc \
			--disable-encoders \
			--disable-decoders \
			--disable-debug \
			--disable-avdevice \
			--disable-devices \
			--disable-avfilter \
			--disable-filters \
			--disable-protocol=concat \
			--disable-bsfs \
			--disable-bzlib \
		    --disable-avresample \
	    	--disable-swresample \
			--disable-iconv \
			--disable-lzma

			
make install-libs install-headers

mkdir -p ../build/contrib/x86_64-apple-darwin10/include/libavutil
find ./libavutil -maxdepth 1 -name \*.h -print
find ./libavutil -maxdepth 1 -name \*.h -exec cp -f {} ../build/contrib/x86_64-apple-darwin10/include/libavutil \;

mkdir -p ../build/contrib/x86_64-apple-darwin10/include/libavcodec
find ./libavcodec -maxdepth 1 -name \*.h -print
find ./libavcodec -maxdepth 1 -name \*.h -exec cp {} ../build/contrib/x86_64-apple-darwin10/include/libavcodec \;

mkdir -p ../build/contrib/x86_64-apple-darwin10/include/libavformat
find ./libavformat -maxdepth 1 -name \*.h -print
find ./libavformat -maxdepth 1 -name \*.h -exec cp  {} ../build/contrib/x86_64-apple-darwin10/include/libavformat \;

mkdir -p ../build/contrib/x86_64-apple-darwin10/include/libswscale
find ./libswscale -maxdepth 1 -name \*.h -print
find ./libswscale -maxdepth 1 -name \*.h -exec cp {} ../build/contrib/x86_64-apple-darwin10/include/libswscale \;

#mkdir -p ../build/contrib/x86_64-apple-darwin10/include/libswresample
#find libswresample -name \*.h -exec cp {} ../build/contrib/x86_64-apple-darwin10/include/libswresample \;

mkdir -p ../build/contrib/x86_64-apple-darwin10/lib/pkgconfig

cp -f libavutil/libavutil.a ../build/contrib/x86_64-apple-darwin10/lib
cp -f libavutil/libavutil.pc ../build/contrib/x86_64-apple-darwin10/lib/pkgconfig

cp -f libavcodec/libavcodec.a ../build/contrib/x86_64-apple-darwin10/lib
cp -f libavcodec/libavcodec.pc ../build/contrib/x86_64-apple-darwin10/lib/pkgconfig

cp -f libavformat/libavformat.a ../build/contrib/x86_64-apple-darwin10/lib
cp -f libavformat/libavformat.pc ../build/contrib/x86_64-apple-darwin10/lib/pkgconfig

cp -f libswscale/libswscale.a ../build/contrib/x86_64-apple-darwin10/lib
cp -f libswscale/libswscale.pc ../build/contrib/x86_64-apple-darwin10/lib/pkgconfig

#cp -f libswresample/libswresample.a ../build/contrib/x86_64-apple-darwin10/lib
#cp -f libswresample/libswresample.pc ../build/contrib/x86_64-apple-darwin10/lib/pkgconfig
