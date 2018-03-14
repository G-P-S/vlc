dos2unix %~dp0\build-contrib.sh
dos2unix %~dp0\build-vlc.sh

SET mypath=%~dp0
setlocal enabledelayedexpansion

set mypath=%mypath::=%
set mypath=%mypath:\=/%

ubuntu -c "cd /mnt/%mypath:~0,-1%/.. && sh build-scripts/build-contrib.sh"  | tee build-contrib-output.txt
ubuntu -c "cd /mnt/%mypath:~0,-1%/.. && sh build-scripts/build-vlc.sh"  | tee build-vlc-output.txt
