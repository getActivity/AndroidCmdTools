cls
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

where bash >nul 2>&1
if errorlevel 1 (
    echo ❌ 未找到 bash 环境！请安装和配置好 Git Bash 环境后再试
    pause
    exit /b 1
)

set "currentDirPath=%~dp0"
pushd "!currentDirPath!\..\.."
set "tempDirPath=%CD%"
popd
set "shellFilePath=!tempDirPath!\shell\device-tools\InstallApp.sh"

if not exist "!shellFilePath!" (
    echo ❌ 没找到 shell 文件，请检查 !shellFilePath! 路径是否正确
    pause
    exit /b 1
)

set "driveLetter=!shellFilePath:~0,1!"
set "shellFilePath=/!driveLetter!/!shellFilePath:~3!"
set "shellFilePath=!shellFilePath:\=/!"

pushd "%~dp0"
bash !shellFilePath!

pause
endlocal