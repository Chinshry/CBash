ffmpeg -i "%~1" -c:v libx264 -preset veryfast -crf 18 -r 29.97 -c:a copy "%~n1_30fps".mp4
pause
