@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM 常用选项菜单
echo 选择一个选项（输入数字）
echo [0] 逆时针旋转90度并垂直翻转
echo [1] 顺时针90
echo [2] 逆时针90
echo [3] 顺时针旋转90度并垂直翻转
echo [4] 横向镜像   Default
echo [5] 竖向镜像
set /p choice=""

if "%choice%"=="0" (
    set "vfCmd=transpose=%choice%"
) else if "%choice%"=="1" (
    set "vfCmd=transpose=%choice%"
) else if "%choice%"=="2" (
    set "vfCmd=transpose=%choice%"
) else if "%choice%"=="3" (
    set "vfCmd=transpose=%choice%"
) else if "%choice%"=="4" (
    set "vfCmd=hflip"
) else if "%choice%"=="5" (
    set "vfCmd=vflip"
) else (
    echo 无效的输入 默认使用[4] 横向镜像
    set "vfCmd=hflip"
)

ffmpeg -i "%~1" -vf "%vfCmd%" "%~n1 trans"%~x1