@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM =================文件导入=======================
if "%~2" == "" (
    echo 请拖拽视频文件和字幕文件到该脚本
    pause
    goto :eof
)

set "videofile="
set "subfile="

:process_args
setlocal enableextensions disabledelayedexpansion
if "%~1" neq "" (
    set "file=%~1"
    set "ext=%~x1"
    setlocal enabledelayedexpansion
    ren "!file!" "%~nx1"
    if /i "!ext:~1!" == "mp4" (
        set "videofile=%~1"
    ) else if /i "!ext:~1!" == "mkv" (
        set "videofile=%~1"
    ) else if /i "!ext:~1!" == "ts" (
        set "videofile=%~1"
    ) else if /i "!ext:~1!" == "ass" (
        set "subfile=%~1"
    ) else if /i "!ext:~1!" == "srt" (
        set "subfile=%~1"
    )
    setlocal disabledelayedexpansion
    shift
    goto process_args
)
endlocal
setlocal enabledelayedexpansion

echo ================READY==================
echo videofile=%videofile%
echo subfile=%subfile%

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
set "CRF=18"
set "GraphicsType=i"
set "configFile=@@config.txt"
for /f "usebackq delims=" %%a in ("%configFile%") do (
    REM 使用等号（=）分割配置项，并将键和值分别存储在变量中
    for /f "tokens=1,2 delims==" %%b in ("%%a") do (
        if "%%b"=="AVSMode" set "AVSMode=%%c"
        if "%%b"=="NeedLogo" set "NeedLogo=%%c"
        if "%%b"=="NeedYadif" set "NeedYadif=%%c"
        if "%%b"=="CRF" set "CRF=%%c"
        if "%%b"=="GraphicsType" set "GraphicsType=%%c"
    )
)

REM =================码率获取=======================
set "videoBitrate=0"
for /f "tokens=3 delims=," %%a in ('ffmpeg -i "%videofile%" 2^>^&1 ^| findstr "bitrate"') do (
    for /f "tokens=2" %%b in ("%%a") do (
        set "videoBitrate=%%b"
    )
)
echo 视频码率=%videoBitrate%
if "%videoBitrate%" NEQ "0" (
	set /a "Bitrate=!videoBitrate! + 1000"
	set /a "BitrateDouble=!Bitrate! * 2"
	set bitrateCmd=-maxrate !Bitrate!k -bufsize !BitrateDouble!k
)
echo 视频码率命令=%bitrateCmd%
echo ==================================

REM =================配置打印=======================
echo 是否AVS压制=%AVSMode%
echo 是否压制Logo=%NeedLogo%
echo 是否反交错=%NeedYadif%
echo CRF=%CRF%
echo 显卡类型=%GraphicsType%
echo 确认以上配置无误，回车开始压制...
pause

echo ================================= 解析开始 =================================
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
    goto :analysisASSLogo
) else (
    echo 无需压制logo
    goto :prepareCmd
)

:analysisASSLogo
set "logoLine="
set "targetStr=.png"

for /f "delims=" %%B in ('type "%subfile%" ^| findstr "%targetStr%"') do (
    set "logoLine=%%B"
    echo !logoLine!
)

if "%logoLine%" == "" (
    echo 没有找到符合条件的LOGO行。
    pause
    goto :eof
)

REM 去掉字符串中的 "&"
set "logoLine=%logoLine:&=%"
set "logoLine=%logoLine::=%"

REM 提取logoPosition
for /f "tokens=2 delims=()" %%i in ("%logoLine%") do (
    set "logoPosition=%%i"
)
set "logoPosition=%logoPosition:,=:%"

REM 提取logoSize
set "regexSize=l (\d+) 0 (\d+) (\d+) (\d+)"
for /F "tokens=8-9" %%a in ('echo "%logoLine%"^| findstr /R "%regexSize%"') do (
  set "logoSize=%%a:%%b"
)

REM 提取logoName
for /f "tokens=1-3 delims=}" %%a in ("%logoLine%") do (
    set "logoName=%%c"
    set "logoPath=res\\logo\\!logoName!"
)

REM 输出结果
echo logoPosition=%logoPosition%
echo logoSize=%logoSize%
echo logoName=%logoName%
echo logoPath=%logoPath%
set "logoCmd=movie='%logoPath%',scale=%logoSize%[wm];[in][wm]overlay=%logoPosition%,"
set "LogoCmdFilter=[1:v]scale=%logoSize%[wm];[m][wm]overlay=%logoPosition%,"


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
    set "subCmd=subtitles='%subcodefile%'"
)
if "%NeedYadif%"=="0" (
    echo 无需反交错
    if "%logoCmd%%subCmd%" == "" (
        set vfCmd=
    ) else (
        set vfCmd=-vf "%logoCmd%%subCmd%"
    )
) else (
    echo 需要反交错
    if "%NeedLogo%"=="1" (
        set vfCmd=-i "%logoPath%" -filter_complex "[0:v]yadif[m];%LogoCmdFilter%%subCmd%"
    ) else (
        set vfCmd=-vf "yadif,%subCmd%"
    )
)

REM =================压制=======================
:compression 
echo ================================= 压制开始 =================================
@echo on
:: CPU HIGHER_QUALIITY
ffmpeg -hide_banner %decodeCmd% -i "%videofile%" %vfCmd% -c:v libx264 -preset veryfast -crf %CRF% %bitrateCmd% -c:a aac "%outputfile%" -y
:: ffmpeg -hide_banner %decodeCmd% -i "%videofile%" -ss 1141.6010909090908 -to 1427.0013636363635 %vfCmd% -c:v libx264 -preset veryfast -crf %CRF% %bitrateCmd% -c:a aac "%outputfile%" -y

:: GPU FASTER
:: N卡_6000K
:: ffmpeg -hide_banner %decodeCmd% -i "%videofile%" %vfCmd% -c:v h264_nvenc -b:v 12000k -c:a aac "%outputfile%" -y
:: A卡_6000K
:: ffmpeg -hide_banner %decodeCmd% -i "%videofile%" %vfCmd% -c:v h264_amf -b:v 12000k -c:a aac "%outputfile%" -y
@echo off
del res\temp\* /Q
echo ================================= 压制完成 =================================
pause
