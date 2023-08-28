@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM =================文件导入=======================
if "%~1" == "" (
  echo 请拖拽视频文件和字幕文件到该脚本
  pause
  goto :eof
)

set "videofile="
set "subfile="

for %%i in (%*) do (
  set "ext=%%~xi"
  if "!ext:~1!" == "mp4" (
    set "videofile=%%~i"
  ) else if "!ext:~1!" == "mkv" (
    set "videofile=%%~i"
  ) else if "!ext:~1!" == "ass" (
    set "subfile=%%~i"
  ) else if "!ext:~1!" == "srt" (
    set "subfile=%%~i"
  )
)

if "%videofile%" == "" (
  echo 没有找到视频文件，请拖拽视频文件和图片文件到该脚本上来。
  pause
  goto :eof
)

if "%subfile%" == "" (
  echo 没有找到字幕文件，请拖拽视频文件和图片文件到该脚本上来。
  pause
  goto :eof
)

set "subcodefile=!subfile:\=\\!"
set "subcodefile=!subcodefile:[=\[!"
set "subcodefile=!subcodefile:]=\]!"
set "subcodefile=!subcodefile::=\:!"
for %%A in ("%videofile%") do (
  set "outputfile=%%~dpnA_output.mp4"
  set "prefile=%%~dpnA_pre%%~xA"
)

REM =================读取配置文件=======================
set "AVSMode=0"
set "NeedLogo=1"
set "NeedYadif=0"
set "GraphicsType=i"
set "configFile=@@config.txt"
for /f "usebackq delims=" %%a in ("%configFile%") do (
    REM 使用等号（=）分割配置项，并将键和值分别存储在变量中
    for /f "tokens=1,2 delims==" %%b in ("%%a") do (
        if "%%b"=="AVSMode" set "AVSMode=%%c"
        if "%%b"=="NeedLogo" set "NeedLogo=%%c"
        if "%%b"=="NeedYadif" set "NeedYadif=%%c"
        if "%%b"=="GraphicsType" set "GraphicsType=%%c"
    )
)
echo 是否AVS压制=%AVSMode%
echo 是否压制Logo=%NeedLogo%
echo 是否反交错=%NeedYadif%
echo 显卡类型=%GraphicsType%
echo 确认以上配置无误，回车开始压制...
pause

REM =================VP90视频判断=======================
for /F "delims=" %%i in ('ffmpeg -i "%videofile%" 2^>^&1 ^| findstr /C:"Stream #0:0"') do (
    echo %%i | findstr /C:"vp9" > nul
    if not errorlevel 1 (
        echo 视频是VP90编码
		goto :handleVP90
    ) else (
		echo 视频非VP90编码
		if "%GraphicsType%" == "n" (
			if "%AVSMode%"=="0" (
				set "decodeCmd=-c:v h264_cuvid "
			)
		)
		goto :handleLogo
	)
)

REM =================预处理VP90=======================
:handleVP90
ffmpeg -ss 0:00:00 -to 10:00:00 -i "%videofile%" -vcodec copy -acodec copy "%prefile%" -y
set "videofile=%prefile%"


REM =================ASS解析=======================
:handleLogo
if "%NeedLogo%"=="1" (
    echo 需要压制logo
	goto :analysisASS
) else (
    echo 无需压制logo
	goto :prepareCmd
)

:analysisASS
set "logoLine="
set "targetStr=.png"

for /f "delims=" %%B in ('type "!subfile!" ^| findstr "%targetStr%"') do (
    set "logoLine=%%B"
	echo !logoLine!
)

if "%logoLine%" == "" (
	echo 没有找到符合条件的LOGO行。
	pause
	goto :eof
)

REM 去掉字符串中的 "&"
set "logoLine=!logoLine:&=!"
set "logoLine=!logoLine::=!"

REM 提取logoPosition
for /f "tokens=2 delims=()" %%i in ("%logoLine%") do (
    set "logoPosition=%%i"
)
set "logoPosition=!logoPosition:,=:!"

REM 提取logoSize
set "regexSize=l (\d+) 0 (\d+) (\d+) (\d+)"
for /F "tokens=8-9" %%a in ('echo "!logoLine!"^| findstr /R "%regexSize%"') do (
  set "logoSize=%%a:%%b"
)

REM 提取logoName
for /f "tokens=1-3 delims=}" %%a in ("%logoLine%") do (
    set "logoName=%%c"
	set "logoPath=res\\logo\\!logoName!"
)

REM 输出结果
echo logoPosition=!logoPosition!
echo logoSize=!logoSize!
echo logoName=!logoName!
echo logoPath=!logoPath!
set "logoCmd=movie='!logoPath!',scale=!logoSize![wm];[in][wm]overlay=!logoPosition!"
set "LogoCmdFilter=[1:v]scale=!logoSize![wm];[m][wm]overlay=!logoPosition!"


REM =================拼凑命令=======================
:prepareCmd
if "%AVSMode%"=="1" (
	echo AVS压制
	set "subCmd="
	del res\temp\* /Q
	echo F|xcopy "%videofile%" res\temp\input.mp4 /r
	echo F|xcopy "%subfile%" res\temp\input.ass /r
	set "videofile=res\input.avs"
) else (
	echo 普通压制
	set "subCmd=,subtitles='%subcodefile%'"
)
if "%NeedYadif%"=="0" (
    echo 无需反交错
	set "vfCmd=-vf "%logoCmd%%subCmd%""
) else (
    echo 需要反交错
	if "%NeedLogo%"=="1" (
		set "vfCmd=-i "%logoPath%" -filter_complex "[0:v]yadif[m];%LogoCmdFilter%%subCmd%""
	) else (
		set "vfCmd=-vf "yadif %logoCmd%%subCmd%""
	)
)

REM =================压制=======================
:compression 
@echo on
:: CPU 压制
ffmpeg %decodeCmd% -i "%videofile%" %vfCmd% -c:v libx264 -preset veryfast -crf 25 -c:a aac "%outputfile%" -y
:: GPU 压制
:: N卡 直压
:: ffmpeg %decodeCmd% -i "%videofile%" -vf "%logoCmd%subtitles='%subcodefile%'" -c:v h264_nvenc -c:a aac "%outputfile%" -y
:: N卡 6000K
:: ffmpeg  %decodeCmd% -i "%videofile%" -vf "%logoCmd%subtitles='%subcodefile%'" -c:v h264_nvenc -b:v 6000k -c:a aac "%outputfile%" -y
:: A卡 直压
:: ffmpeg %decodeCmd% -i "%videofile%" -vf "%logoCmd%subtitles='%subcodefile%'" -c:v h264_amf -c:a aac "%outputfile%" -y
:: A卡 6000K
:: ffmpeg %decodeCmd% -i "%videofile%" -vf "%logoCmd%subtitles='%subcodefile%'" -c:v h264_amf -b:v 6000k -c:a aac "%outputfile%" -y

del res\temp\* /Q

pause
