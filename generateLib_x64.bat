REM https://wiki.videolan.org/GenerateLibFromDll/
@Echo OFF
echo EXPORTS > %~dp0\libvlc.def
for /f "usebackq tokens=4,* delims=_ " %%i in (`dumpbin /exports %~dp0\libvlc.dll`) do if %%i==libvlc echo %%i_%%j >> %~dp0\libvlc.def
echo EXPORTS > %~dp0\libvlccore.def
for /f "usebackq tokens=4,* delims=_ " %%i in (`dumpbin /exports %~dp0\libvlccore.dll`) do if %%i==libvlc echo %%i_%%j >> %~dp0\libvlccore.def
lib /def:%~dp0\libvlc.def /out:%~dp0\libvlc.lib /machine:x64
lib /def:%~dp0\libvlccore.def /out:%~dp0\libvlccore.lib /machine:x64
rm -f %~dp0\libvlc.def
rm -f %~dp0\libvlc.exp
rm -f %~dp0\libvlccore.def
rm -f %~dp0\libvlccore.exp
