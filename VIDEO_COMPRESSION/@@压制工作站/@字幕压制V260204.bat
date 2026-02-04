@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM =================文件导入=======================
if "%~2" == "" (
    echo *****************************************************
    echo 请拖拽视频文件和字幕文件到该脚本
    echo *****************************************************
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
    ) else if /i "!ext:~1!" == "mov" (
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

echo ============================READY==============================
echo videofile=%videofile%
echo subfile=%subfile%

if "%videofile%" == "" (
    echo *****************************************************
    echo 没有找到视频文件，请拖拽视频文件和图片文件到该脚本上。
    echo *****************************************************
    pause
    goto :eof
)

if "%subfile%" == "" (
    echo *****************************************************
    echo 没有找到字幕文件，请拖拽视频文件和图片文件到该脚本上。
    echo *****************************************************
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
set "MaxBitrate=-1"
set "GraphicsType=i"
set "configFile=@@config.txt"
for /f "usebackq delims=" %%a in ("%configFile%") do (
    REM 使用等号（=）分割配置项，并将键和值分别存储在变量中
    for /f "tokens=1,2 delims==" %%b in ("%%a") do (
        if "%%b"=="AVSMode" set "AVSMode=%%c"
        if "%%b"=="NeedLogo" set "NeedLogo=%%c"
        if "%%b"=="NeedYadif" set "NeedYadif=%%c"
        if "%%b"=="CRF" set "CRF=%%c"
        if "%%b"=="MaxBitrate" set "MaxBitrate=%%c"
        if "%%b"=="GraphicsType" set "GraphicsType=%%c"
    )
)

REM =================码率获取=======================
if "%MaxBitrate%" NEQ "-1" (
    set "videoBitrate=0"
    if "%MaxBitrate%"=="0" (
        for /f "tokens=3 delims=," %%a in ('ffmpeg -i "%videofile%" 2^>^&1 ^| findstr "bitrate"') do (
            for /f "tokens=2" %%b in ("%%a") do (
                echo 视频码率=%%b
                set "videoBitrate=%%b + 1000"
            )
        )
    ) else (
        set "videoBitrate=%MaxBitrate%"
    )
    if "%videoBitrate%" NEQ "0" (
        set /a "Bitrate=!videoBitrate!"
        set /a "BitrateDouble=!Bitrate! * 2"
        set bitrateCmd=-maxrate !Bitrate!k -bufsize !BitrateDouble!k
    )
    echo 视频码率命令=!bitrateCmd!
) else (
    set "bitrateCmd="
    echo 不限制视频码率
)

echo ==============================================================

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
    goto :findASSLogo
)

:findASSLogo
if "%logoLine%" == "" (
    echo *****************************************************
    echo 没有找到符合条件的LOGO行！
    echo 若不需要LOGO请按回车仍继续压制，否则请关闭窗口退出压制。
    echo *****************************************************
    pause
    goto :prepareCmd
)

for /f "delims=" %%C in ('echo "!logoLine!" ^| findstr /r "^Dialogue:"') do (
    echo *****************************************************
    echo 未注释LOGO行！请注释后再进行压制！
    echo *****************************************************
    goto :eof
)

echo =======================LOGO解析开始=======================

REM 提取ASS PlayResX和PlayResY的值
for /f "tokens=2 delims=:" %%a in ('findstr /i "PlayResX" "%subfile%"') do set "PlayResX=%%a"
for /f "tokens=2 delims=:" %%a in ('findstr /i "PlayResY" "%subfile%"') do set "PlayResY=%%a"
set "PlayResX=%PlayResX: =%"
set "PlayResY=%PlayResY: =%"
echo PlayResX:PlayResY: %PlayResX%:%PlayResY%
        
REM 提取视频分辨率
for /f "tokens=*" %%a in ('ffmpeg -i "%videofile%" 2^>^&1 ^| findstr /c:" Video:" ^| findstr /c:"default" ^| findstr /r "[0-9][0-9]*x[0-9][0-9]*"') do (
    set "line=%%a"
    for %%a in (!line!:,= %) do (
        echo %%a | findstr /r "[0-9][0-9][0-9]*x[0-9][0-9][0-9]*" >nul
        if not errorlevel 1 (
            for /f "tokens=1,2 delims=x" %%w in ("%%a") do (
                set "videoWidth=%%w"
                set "videoHeight=%%x"
            )
        )
    )
)
set "videoWidth=%videoWidth: =%"
set "videoHeight=%videoHeight: =%"
echo videoWidth:videoHeight: %videoWidth%:%videoHeight%

REM 得到放大倍数multiple
for /f "delims=" %%a in ('powershell "%videoWidth%/%PlayResX%"') do set multipleX=%%a
for /f "delims=" %%a in ('powershell "%videoHeight%/%PlayResY%"') do set multipleY=%%a
set /a multiple=multipleX
echo multiple: %multiple%
if %multipleX% == %multipleY% (
    if %multipleX% neq 1 (
        echo =====ass和视频文件分辨率不匹配 需要将logo参数 x %multipleX%=======
    )    
)

REM 去掉字符串中的 "&"
set "logoLine=%logoLine:&=%"
set "logoLine=%logoLine::=%"

REM 提取logoPosition
for /f "tokens=2 delims=()" %%i in ("%logoLine%") do (
    set "logoPosition=%%i"
    for /f "tokens=1,2 delims=:," %%w in ("%%i") do (
        set "logoPositionX=%%w"
        set "logoPositionY=%%x"
        for /f "delims=" %%a in ('powershell "!logoPositionX!*%multiple%"') do set logoPositionMultiX=%%a
        for /f "delims=" %%a in ('powershell "!logoPositionY!*%multiple%"') do set logoPositionMultiY=%%a
    )
)
echo logoPositionX:logoPositiony: %logoPositionX%:%logoPositiony%
echo logoPositionMultiX:logoPositionMultiY: %logoPositionMultiX%:%logoPositionMultiY%
set "logoPosition=%logoPositionMultiX%:%logoPositionMultiY%"

REM 提取logoSize
set "regexSize=l (\d+) 0 (\d+) (\d+) (\d+)"
for /F "tokens=8-9" %%a in ('echo "%logoLine%"^| findstr /R "%regexSize%"') do (
    set "logoSizeWidth=%%a"
    set "logoSizeHeight=%%b"
    for /f "delims=" %%d in ('powershell "!logoSizeWidth!*%multiple%"') do set logoSizeMultiWidth=%%d
    for /f "delims=" %%d in ('powershell "!logoSizeHeight!*%multiple%"') do set logoSizeMultiHeight=%%d
)
echo logoSizeWidth:logoSizeHeight: %logoSizeWidth%:%logoSizeHeight%
echo logoSizeMultiWidth:logoSizeMultiHeight: %logoSizeMultiWidth%:%logoSizeMultiHeight%
set "logoSize=%logoSizeMultiWidth%:%logoSizeMultiHeight%"

REM 提取logoName
for /f "tokens=1-3 delims=}" %%a in ("%logoLine%") do (
    set "logoName=%%c"
    set "logoPath=res\\logo\\!logoName!"
)

REM 输出结果
echo =======================LOGO解析完成=======================
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
    if not exist "res\temp\" mkdir "res\temp"
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
