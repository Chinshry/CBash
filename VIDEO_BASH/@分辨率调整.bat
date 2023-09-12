@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM 常用选项菜单
echo 选择一个选项（输入数字）
echo [1] 横屏 1080 
echo [2] 横屏 720
echo [3] 竖屏 1080
echo [4] 竖屏 720
echo [5] 自定义分辨率
set /p choice=""

REM 根据用户选择设置宽高比
if "%choice%"=="1" (
    set "aspect_ratio=-1:1080"
) else if "%choice%"=="2" (
    set "aspect_ratio=-1:720"
) else if "%choice%"=="3" (
    set "aspect_ratio=1080:-1"
) else if "%choice%"=="4" (
    set "aspect_ratio=720:-1"
) else if "%choice%"=="5" (
    set /p aspect_ratio="请输入自定义分辨率（宽:高）："
) else (
    echo 无效的输入 默认使用[1] 横屏 1080
    set "aspect_ratio=-1:1080"
)

REM 将冒号替换为下划线
set "aspect_ratio_str=!aspect_ratio::=_!"
ffmpeg -i "%~1" -vf scale=!aspect_ratio! -y "%~n1_!aspect_ratio_str!"%~x1