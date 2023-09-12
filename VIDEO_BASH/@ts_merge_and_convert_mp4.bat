@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

set "folder=%~1"
for %%F in ("%folder%") do set "output_name=%%~nF"

copy /b  %folder%\*.ts  %output_name%.ts
ffmpeg -i %output_name%.ts -vcodec copy -acodec copy %output_name%.mp4
del %output_name%.ts
