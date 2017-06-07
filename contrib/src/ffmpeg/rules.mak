# FFmpeg

#Uncomment the one you want
#USE_LIBAV ?= 1
USE_FFMPEG ?= 1

ifdef USE_FFMPEG
HASH=cdb0225
FFMPEG_SNAPURL := http://git.videolan.org/?p=ffmpeg.git;a=snapshot;h=$(HASH);sf=tgz
FFMPEG_GITURL := git://git.videolan.org/ffmpeg.git
else
HASH=c457bde
FFMPEG_SNAPURL := http://git.libav.org/?p=libav.git;a=snapshot;h=$(HASH);sf=tgz
FFMPEG_GITURL := git://git.libav.org/libav.git
endif

FFMPEGCONF = \
	--cc="$(CC)" \
	--pkg-config="$(PKG_CONFIG)" \
    --disable-everything \
	--enable-hwaccels

# DEMUXERS
FFMPEGCONF += \
	--enable-demuxer=aac \
	--enable-demuxer=mp3 \
	--enable-demuxer=mp4 \
	--enable-demuxer=mov \
	--enable-demuxer=avi \
	--enable-demuxer=matroska

# DECODERS
FFMPEGCONF += \
	--enable-decoder=pcm_s16le \
	--enable-decoder=pcm_s16be \
	--enable-decoder=aac \
	--enable-decoder=flac \

# PARSERS
FFMPEGCONF += \
	--enable-parser=h264 \
	--enable-parser=hevc \
	--enable-parser=aac \
	--enable-parser=flac 

# PROTOCOLS
FFMPEGCONF += \
	--enable-protocol=file \
	--enable-protocol=http \


DEPS_ffmpeg = zlib gsm openjpeg

ifdef BUILD_ENCODERS
$(WARNING You are trying to build encoders, you should not.)
endif

ifdef HAVE_CROSS_COMPILE
FFMPEGCONF += --enable-cross-compile --disable-programs
ifndef HAVE_DARWIN_OS
FFMPEGCONF += --cross-prefix=$(HOST)-
endif
endif

# MIPS stuff
ifeq ($(ARCH),mipsel)
FFMPEGCONF += --arch=mips
endif

# x86 stuff
ifeq ($(ARCH),i386)
ifndef HAVE_DARWIN_OS
FFMPEGCONF += --arch=x86
endif
endif

# Darwin
ifdef HAVE_DARWIN_OS
FFMPEGCONF += --arch=$(ARCH) --target-os=darwin
ifdef USE_FFMPEG
FFMPEGCONF += --disable-lzma
endif
ifeq ($(ARCH),x86_64)
FFMPEGCONF += --cpu=core2
endif
endif
ifdef HAVE_IOS
FFMPEGCONF += --enable-pic --extra-ldflags="$(EXTRA_CFLAGS)"
ifdef HAVE_NEON
FFMPEGCONF += --as="$(AS)"
endif
endif
ifdef HAVE_MACOSX
FFMPEGCONF += --enable-vda
endif

# Linux
ifdef HAVE_LINUX
FFMPEGCONF += --target-os=linux --enable-pic

endif

# Windows
ifdef HAVE_WIN32
ifndef HAVE_MINGW_W64
DEPS_ffmpeg += directx
endif
FFMPEGCONF += --target-os=mingw32 --enable-memalign-hack
FFMPEGCONF += --enable-w32threads --enable-dxva2 \
	--disable-decoder=dca

ifdef HAVE_WIN64
FFMPEGCONF += --cpu=athlon64 --arch=x86_64
else # !WIN64
FFMPEGCONF+= --cpu=i686 --arch=x86
endif

else # !Windows
FFMPEGCONF += --enable-pthreads
endif

# Solaris
ifdef HAVE_SOLARIS
ifeq ($(ARCH),x86_64)
FFMPEGCONF += --cpu=core2
endif
FFMPEGCONF += --target-os=sunos --enable-pic
endif

# Build
PKGS += ffmpeg
ifeq ($(call need_pkg,"libavcodec >= 54.25.0 libavformat >= 53.21.0 libswscale"),)
PKGS_FOUND += ffmpeg
endif

$(TARBALLS)/ffmpeg-$(HASH).tar.xz:
	$(call download_git,$(FFMPEG_GITURL),,$(HASH))

.sum-ffmpeg: $(TARBALLS)/ffmpeg-$(HASH).tar.xz
	$(warning Not implemented.)
	touch $@

ffmpeg: ffmpeg-$(HASH).tar.xz .sum-ffmpeg
	rm -Rf $@ $@-$(HASH)
	mkdir -p $@-$(HASH)
	$(XZCAT) "$<" | (cd $@-$(HASH) && tar xv --strip-components=1)
	$(APPLY) $(SRC)/ffmpeg/xwd-8431629dd112874293380a6d8a852459fc1a76b6.patch
	$(MOVE)

.ffmpeg: ffmpeg
	cd $< && $(HOSTVARS) ./configure \
		--extra-ldflags="$(LDFLAGS)" $(FFMPEGCONF) \
		--prefix="$(PREFIX)" --enable-static --disable-shared
	cd $< && $(MAKE) install-libs install-headers
	touch $@
