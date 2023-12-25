@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:main_menu
echo 选择一个选项（输入数字）
echo [1] 旋转镜像
echo [2] 分辨率调整 
echo [3] 帧率调整
echo [4] 码率调整
echo [5] 反交错
set /p main_choice=""
echo ======================================

if "%main_choice%"=="1" (
    goto :video_rotation_menu
) else if "%main_choice%"=="2" (
    goto :video_resolution_menu
) else if "%main_choice%"=="3" (
    goto :video_frame_menu
) else if "%main_choice%"=="4" (
    goto :video_bitrate_menu
)  else if "%main_choice%"=="5" (
    goto :video_vadif_menu
) else (
    echo 无效的输入，请重新输入
    goto main_menu
)
pause
exit /b

:video_rotation_menu
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

ffmpeg -i "%~1" -vf "%vfCmd%" -preset veryfast -crf 18 "%~n1_trans"%~x1
goto :EOF

:video_resolution_menu
echo 选择一个选项（输入数字）
echo [1] 横屏 4K
echo [2] 横屏 1080 Default
echo [3] 横屏 720
echo [4] 竖屏 1080
echo [5] 竖屏 720
echo [6] 自定义分辨率
set /p choice=""

if "%choice%"=="1" (
    set "aspect_ratio=-1:2160"
) else if "%choice%"=="2" (
    set "aspect_ratio=-1:1080"
) else if "%choice%"=="3" (
    set "aspect_ratio=-1:720"
) else if "%choice%"=="4" (
    set "aspect_ratio=1080:-1"
) else if "%choice%"=="5" (
    set "aspect_ratio=720:-1"
) else if "%choice%"=="6" (
    set /p aspect_ratio="请输入自定义分辨率（宽:高）："
) else (
    echo 无效的输入 默认使用[2] 横屏 1080
    set "aspect_ratio=-1:1080"
)

REM 将冒号替换为下划线
set "aspect_ratio_str=!aspect_ratio::=_!"
echo path=%%~1
echo aspect_ratio_str=%aspect_ratio_str%
ffmpeg -i "%~1" -vf scale=!aspect_ratio! "%~n1_!aspect_ratio_str!"%~x1
goto :EOF

:video_frame_menu
echo 选择一个选项（输入数字）
echo [1] 30   Default
echo [2] 自定义码率
set /p choice=""

if "%choice%"=="1" (
    set "video_frame=30"
) else if "%choice%"=="2" (
    set /p video_frame="请输入自定义码率(纯数字)："
) else (
    echo 无效的输入 默认使用[1] 30
    set "video_frame=30"
)

ffmpeg -i "%~1" -preset veryfast -crf 18 -r !video_frame! -c:a copy "%~n1_!video_frame!fps".mp4
goto :EOF

:video_bitrate_menu
echo 选择一个选项（输入数字）
echo [1] 较高 8000   Default
echo [2] B站 6500
echo [3] 中等 4000
echo [4] 最低 800
echo [5] 自定义码率
set /p choice=""

if "%choice%"=="1" (
    set "video_bitrate=8000"
) else if "%choice%"=="2" (
    set "video_bitrate=6500"
) else if "%choice%"=="3" (
    set "video_bitrate=4000"
) else if "%choice%"=="4" (
    set "video_bitrate=800"
) else if "%choice%"=="5" (
    set /p video_bitrate="请输入自定义码率(纯数字)："
) else (
    echo 无效的输入 默认使用[1] 较高 8000
    set "video_bitrate=8000"
)

set "video_bitrate_str=!video_bitrate!k"
ffmpeg -i "%~1" -b:v !video_bitrate_str! -c:a copy "%~n1_!video_bitrate_str!"%~x1
goto :EOF

:video_vadif_menu
ffmpeg -i "%~1" -preset veryfast -crf 18 -vf "yadif" "%~n1_yadif".mp4
goto :EOF