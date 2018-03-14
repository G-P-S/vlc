dos2unix %~dp0\build-contrib.sh

SET mypath=%~dp0
setlocal enabledelayedexpansion

set mypath=%mypath::=%
set mypath=%mypath:\=/%

ubuntu -c "cd /mnt/%mypath:~0,-1%/.. && sh build-scripts/build-contrib.sh" | tee build-contrib-output.txt