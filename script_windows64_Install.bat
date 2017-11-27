:: set paths and names
set "DEST_PATH=\\10.129.33.16\data\releases\KVLC\master\Windows"

:: create temp directory, copy libraries&headers
mkdir temp_Windows\lib
mkdir temp_Windows\plugins
mkdir temp_Windows\include
xcopy /Y x64\Release\libvlc*.lib temp_Windows\lib
xcopy /Y x64\Release\libcompat.lib temp_Windows\lib
xcopy /Y x64\Release\libvlc*.dll temp_Windows\lib
xcopy /Y x64\Release\libcompat.dll temp_Windows\lib
xcopy /Y x64\Release\plugins\* temp_Windows\plugins /E
xcopy /Y include\vlc\* temp_Windows\include\vlc\
xcopy /Y include\* temp_Windows\include\vlc\plugins\ 
if exist temp_Windows\include\vlc\plugins\.gitignore ( del temp_Windows\include\vlc\plugins\.gitignore )

:: apply script to filter plugins
cd temp_Windows
python ../VLC-make-free.py
cd ..

:: clean Gaia and copy
rd /S /Q %DEST_PATH%
if exist %DEST_PATH% ( rmdir /S /Q %DEST_PATH% )
mkdir %DEST_PATH%
xcopy /Y temp_Windows\* %DEST_PATH% /E

:: destroy temp directory
rd /S /Q temp_Windows
if exist temp_Windows ( rmdir /S /Q temp_Windows )

