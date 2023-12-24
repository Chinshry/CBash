chcp 65001 > nul
@echo off
setlocal enabledelayedexpansion

if "%~1" == "" (
  echo 请拖拽视频文件和图片文件到该脚本上来。
  pause
  goto :eof
)

set "use_image=0"
set "videofile="
set "imagefile="

for %%i in (%*) do (
  set "ext=%%~xi"
  if "!ext:~1!" == "mp4" (
    set "videofile=%%~fi"
  ) else if "!ext:~1!" == "mkv" (
    set "videofile=%%~fi"
  ) else if "!ext:~1!" == "jpg" (
    set "imagefile=%%~fi"
  )
)

if "%videofile%" == "" (
  echo 没有找到视频文件，请拖拽视频文件和图片文件到该脚本上来。
  pause
  goto :eof
)

if "%imagefile%" == "" (
  echo 没有找到图片文件，请拖拽视频文件和图片文件到该脚本上来。
  pause
  goto :eof
)

if "%use_image%"=="1" (
    for %%A in ("%imagefile%") do (
        set "tempfile=%%~dpnA_temp.mp4"
        set "finalName=%%~nA.mp4"
    )
) else (
    for %%A in ("%videofile%") do (
        set "tempfile=%%~dpnA_temp%%~xA"
        set "finalName=%%~nxA"
    )
)

echo 修改中，请稍等...
ffmpeg -i "%videofile%" -i "%imagefile%" -map 1 -map 0 -c copy -disposition:0 attached_pic "%tempfile%"

echo 清理中，请稍等...
del /s /q "%videofile%"
del /s /q "%imagefile%"
ren "%tempfile%" "%finalName%"

echo 完成！输出文件为：%finalName%