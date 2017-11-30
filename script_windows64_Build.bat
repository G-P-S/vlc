:: set paths and names
set "FFMPEG_ARCHIVE=ffmpeg_visual_x64_3.3.5.r89114"
set "WGET_EXE=C:\Program Files (x86)\GnuWin32\bin\wget.exe"	
set "SEVENZ_EXE=C:\Program Files\7-Zip\7z.exe"
set "MSBUILD_EXE=C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"

:: download and unzip FFmpeg Visual libs
if exist "contrib\win32" (
	echo FOLDER contrib\win32 already exists, skip FFmpeg download
) else (
	mkdir contrib\win32
	"%WGET_EXE%" --no-check-certificate -P contrib\win32 https://s3-us-west-2.amazonaws.com/kendata/static-libs/FFmpeg_visual_x64/%FFMPEG_ARCHIVE%.zip
	"%SEVENZ_EXE%" x -y "contrib\win32\%FFMPEG_ARCHIVE%.zip" -owin32 
)

:: build VLC project
"%MSBUILD_EXE%" winvlc.sln /p:Configuration=Release /p:Platform=x64 /t:Clean,Build

:: clean directories
rd /S /Q "contrib\win32"
rd /S /Q "win32\lib"
if exist "contrib\win32" ( rmdir /S /Q "contrib\in32" )
if exist "win32\lib" ( rmdir /S /Q "win32\lib" )
