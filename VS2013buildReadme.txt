This file explains the steps necessary for VLC build for Microsoft Visual Studio 2013 with Windows SDK 8.1 installed on the build PC

First one needs to build 3 party libraries used by VLC
1) clone https://github.com/ShiftMediaProject/FFmpeg
2) go to SMP directory and run project_get_dependencies.bat
	If for some reason it complains that  "A working copy of git was not found. To use this script you must first install git for windows." just comment the corresponding check in this bat file. It will get all dependencies necessary for the build.
3) When everything in place open in VS 2013 ffmpeg_deps.sln located in SMP folder and build it in Release config. It will create static libraries located in ../msvc/lib/x64 or ../msvc/lib/x86 folder and the headers necessary for include in ../msvc/include
4) Copy the libs obtained on step 3) to VLC/Win32/x64 for 64 bit libs or VLC/Win32/ for 32 bit libs and headers obtained on step 3) to VLC/Win32 include keeping internal folder structure as is.
5) Build winvlc.sln located in VLC root folder.
6)Enjoy the result or complain to victoria.zhislina@intel.com :)